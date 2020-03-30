defmodule Staxx.Store.Testchain.Adapters.DETS do
  @moduledoc """
  Implementation of StoreAdapter behaviour for DETS store.
  This adapter works as GenServer.
  It makes DETS table initializing in GenServer's init/1 callback.
  It closes DETS table in GenServer's terminate/2 callback.
  """
  use GenServer
  require Logger

  @behaviour Staxx.Store.Testchain.SnapshotsStore

  # Snapshots table name used as DETS file name
  @snapshots_table "snapshots"

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc """
  Returns module name to start under supervisor.
  """
  @impl true
  def child_spec(), do: [__MODULE__]

  @impl true
  @doc """
  Makes init for DETS Snapshots table: looks for table files directory, if directory doesn't exist, creates new one.
  Creates DETS table file if file doesn't exist.
  """
  def init(state) do
    unless File.dir?(db_path()) do
      File.mkdir_p!(db_path())
    end

    :dets.open_file(snapshots_table(), type: :set)
    {:ok, state}
  end

  @impl true
  @doc """
  Closes DETS table.
  """
  def terminate(_, _) do
    Logger.debug("#{__MODULE__} terminating... Closing DETS...")
    :dets.close(snapshots_table())
  end

  @impl true
  @doc """
  Stores new snapshot into DETS table.
  Returns :ok in success case.
  Return {:error, term()} in error case.
  """
  @spec store(map()) :: :ok | {:error, term()}
  def store(%{id: id, chain: chain} = snapshot),
    do: :dets.insert(snapshots_table(), {id, chain, snapshot})

  @impl true
  @doc """
  Loads snapshot details by id from DETS table.
  In case of error it might raise an exception.
  Returns nil if nothing found.
  """
  @spec by_id(binary) :: map() | nil
  def by_id(id) do
    case :dets.lookup(snapshots_table(), id) do
      [] ->
        nil

      [{^id, _, snapshot}] ->
        snapshot
    end
  end

  @impl true
  @doc """
  Loads list of existing snapshots by chain type from DETS table.
  """
  @spec by_chain(binary) :: [map()]
  def by_chain(chain) do
    snapshots_table()
    |> :dets.match({:_, chain, :"$1"})
    |> Enum.map(fn [snap] -> snap end)
  end

  @doc """
  Removes snapshot details from DETS table.
  Always returns :ok.
  """
  @impl true
  @spec remove(binary) :: :ok
  def remove(id), do: :dets.delete(snapshots_table(), id)

  @doc """
  Removes all data in DETS snapshots table.
  Returns :ok in success case.
  Returns {:error, term()} in error case.
  """
  @spec clear_snapshots_table :: :ok | {:error, term()}
  def clear_snapshots_table() do
    snapshots_table()
    |> :dets.delete_all_objects()
  end

  #
  # Returns path to DETS files directory
  #
  @spec db_path :: binary
  defp db_path() do
    :testchain
    |> Application.get_env(:dets_db_path)
    |> Path.expand()
  end

  #
  # Returns path to DETS file for snapshots table
  #
  @spec snapshots_table :: any()
  defp snapshots_table() do
    db_path()
    |> Path.join(@snapshots_table)
    |> String.to_atom()
  end
end
