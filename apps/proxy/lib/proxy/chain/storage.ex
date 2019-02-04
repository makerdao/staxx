defmodule Proxy.Chain.Storage do
  @moduledoc """
  Storage module that will store all workers that spawn on service
  """

  use GenServer
  require Logger

  @table "chain_workers"

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(_) do
    Logger.debug("#{__MODULE__}: Starting chain worker storage")

    unless File.dir?(db_path()) do
      File.mkdir_p(db_path())
    end

    :dets.open_file(table(), type: :set)
  end

  @doc false
  def terminate(_, _) do
    Logger.debug("#{__MODULE__} terminating... Closing DETS...")
    :dets.close(table())
  end

  @doc """
  Store new worker state in DETS
  """
  @spec store(binary, Proxy.Chain.Worker.State.t()) :: :ok | {:error, term()}
  def store(id, worker_state),
    do: :dets.insert(table(), {id, worker_state})

  @doc """
  Load all existing worker details
  """
  @spec all() :: [Proxy.Chain.Worker.State.t()]
  def all() do
    table()
    |> :dets.match({:_, :"$1"})
    |> Enum.map(fn [worker] -> worker end)
  end

  @doc """
  Get chain worker details by it's id
  """
  @spec get(binary) :: nil | map()
  def get(id) do
    case :dets.lookup(table(), id) do
      [] ->
        nil

      [{^id, worker}] ->
        worker
    end
  end

  @doc """
  Delete existing chain worker details
  """
  @spec delete(binary) :: :ok | {:error, term()}
  def delete(id), do: :dets.delete(table(), id)

  # get path to DETS file for storage chain workers
  defp db_path() do
    :proxy
    |> Application.get_env(:dets_db_path)
    |> Path.expand()
  end

  # Get full table path
  defp table() do
    db_path()
    |> Path.join(@table)
    |> String.to_atom()
  end
end
