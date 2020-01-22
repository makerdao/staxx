defmodule Staxx.Store.Testchain.Adapters.Postgres do
  @moduledoc """
  Implementation of Staxx.Store.Adapter behaviour for Postgresql.
  Uses Staxx.Store.Models.Snapshot schema for database operations.
  Adapter functions returns converted to map structs from Repo using Map.from_struct/1.
  init/0 and release/0 functions are empty because Repo is already on and ready to use.
  child_spec/0 function returns empty list becase this adapter shouldn't start on Application start.
  """

  import Ecto.Query
  alias Staxx.Store.Testchain.Models.Snapshot
  alias Staxx.Store.Repo

  @behaviour Staxx.Store.Testchain.SnapshotsStore

  @doc """
  Returns empty list, so module doesn't start under supervisor.
  """
  @impl true
  def child_spec(), do: []

  @impl true
  @doc """
  Inserts given snapshot details map in to db.
  Returns :ok in success case.
  Returns {:error, term()} in error case.
  """
  @spec store(map()) :: :ok | {:error, term()}
  def store(snapshot_data) do
    %Snapshot{}
    |> Snapshot.changeset_for_create(snapshot_data)
    |> Repo.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, message} -> {:error, message}
    end
  end

  @impl true
  @doc """
  Returns snapshot data as map by given id.
  Returns nil if nothing found.
  """
  @spec by_id(binary) :: map()
  def by_id(id) do
    from(s in Snapshot, where: s.id == ^id)
    |> Repo.one()
    |> case do
      nil -> nil
      snapshot -> prepare_for_output(snapshot)
    end
  end

  @impl true
  @doc """
  Returns list of snapshot as maps by given chain type.
  Passed parameter may be string or atom. In case of atom it converts atom to string value.
  """
  @spec by_chain(atom | binary) :: [map()]
  def by_chain(chain_type) when is_atom(chain_type) do
    chain_type
    |> Atom.to_string()
    |> by_chain()
  end

  def by_chain(chain_type) do
    from(s in Snapshot, where: s.chain == ^chain_type)
    |> Repo.all()
    |> Enum.map(fn s -> prepare_for_output(s) end)
  end

  @impl true
  @doc """
  Removes snapshot detail by given id.
  Always returns :ok.
  """
  @spec remove(binary) :: :ok
  def remove(id) do
    from(s in Snapshot, where: s.id == ^id)
    |> Repo.one()
    |> Repo.delete()

    :ok
  end

  defp prepare_for_output(snapshot) do
    snapshot
    |> Map.from_struct()
    |> atomize_chain_type()
  end

  defp atomize_chain_type(%{chain: chain} = data) when is_binary(chain),
    do: Map.put(data, :chain, String.to_atom(chain))

  defp atomize_chain_type(data), do: data
end
