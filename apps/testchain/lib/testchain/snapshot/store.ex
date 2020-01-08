defmodule Staxx.Testchain.SnapshotStore do
  @moduledoc """
  Module that handle snapshots storage

  TODO: rework with adapter pattern
  """
  use GenServer
  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.SnapshotDetails
  alias Staxx.Testchain.Helper

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    unless File.dir?(Helper.dets_db_path()) do
      File.mkdir(Helper.dets_db_path())
    end

    :dets.open_file(Helper.snapshots_table(), type: :set)
  end

  @doc false
  def terminate(_, _) do
    Logger.debug("#{__MODULE__} terminating... Closing DETS...")
    :dets.close(Helper.snapshots_table())
  end

  @doc """
  Store new snapshot into local DB
  """
  @spec store(SnapshotDetails.t()) :: :ok | {:error, term()}
  def store(%SnapshotDetails{id: id, chain: chain} = snapshot),
    do: :dets.insert(Helper.snapshots_table(), {id, chain, snapshot})

  @doc """
  Load snapshot details by id
  In case of error it might raise an exception
  """
  @spec by_id(binary) :: SnapshotDetails.t() | nil
  def by_id(id) do
    case :dets.lookup(Helper.snapshots_table(), id) do
      [] ->
        nil

      [{^id, _, snapshot}] ->
        snapshot
    end
  end

  @doc """
  Load list of existing snapshots by chain type
  """
  @spec by_chain(Testchain.evm_type()) :: [SnapshotDetails.t()]
  def by_chain(chain) do
    Helper.snapshots_table()
    |> :dets.match({:_, chain, :"$1"})
    |> Enum.map(fn [snap] -> snap end)
  end

  @doc """
  Remove snapshot details from local DB
  """
  @spec remove(binary) :: :ok
  def remove(id), do: :dets.delete(Helper.snapshots_table(), id)
end
