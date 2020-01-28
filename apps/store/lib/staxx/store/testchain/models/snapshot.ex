defmodule Staxx.Store.Testchain.Models.Snapshot do
  @moduledoc """
  Model of testchain snapshot.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: binary,
          description: binary,
          path: binary,
          chain: binary | atom
        }

  @primary_key {:id, :string, autogenerate: false}
  schema "snapshots" do
    field(:description, :string)
    field(:path, :string)
    field(:chain, :string)
    timestamps()
  end

  @fields [:description, :path, :chain, :id]
  @chain_types ["geth", "ganache", "geth_vdb", "parity"]
  @chain_type_validation_error_message "Invalid chainset type. Must be one of 'geth' or 'ganache' or 'geth_vdb' or 'parity'"

  @doc """
  Changeset to create Snapshot.
  Validates chain type field, value should be one of "geth" or "ganache" or "geth_vdb" or "parity".
  Returns changeset.
  """
  @spec changeset_for_create(t(), map()) :: Ecto.Changeset.t()
  def changeset_for_create(data, params) do
    data
    |> cast(stringify_chain_type(params), @fields)
    |> validate_required(@fields)
    |> validate_chain_type()
  end

  #
  # Checks if chain is one of the @chain_types.
  # Adds error to changeset if check fails.
  #
  defp validate_chain_type(
         %Ecto.Changeset{valid?: true, changes: %{chain: chain_type}} = changeset
       ) do
    chain_type
    |> case do
      t when t in @chain_types -> changeset
      _ -> add_error(changeset, :chain, @chain_type_validation_error_message)
    end
  end

  #
  # Converts :chain key value from atom to string.
  #
  defp stringify_chain_type(%{chain: chain} = data) when is_atom(chain),
    do: Map.put(data, :chain, Atom.to_string(chain))

  defp stringify_chain_type(data), do: data
end
