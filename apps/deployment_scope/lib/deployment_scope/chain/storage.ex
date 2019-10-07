defmodule Staxx.DeploymentScope.Chain.Storage do
  @moduledoc """
  Storage module that will store all chain processes that spawn on service
  """
  use GenServer

  require Logger

  alias Staxx.DeploymentScope.Chain.Storage.Record
  alias Staxx.DeploymentScope.Chain.State

  @table "chain_workers"

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(_) do
    Logger.debug("#{__MODULE__}: Starting chain process storage")

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
  Store new chain process state in DETS
  """
  @spec store(Record.t()) :: :ok | {:error, term()}
  def store(%Record{id: id} = record),
    do: :dets.insert(table(), {id, record})

  @doc """
  Load all existing chain process details
  """
  @spec all() :: [State.t()]
  def all() do
    table()
    |> :dets.match({:_, :"$1"})
    |> List.flatten()
  end

  @doc """
  Get chain process details by it's id
  """
  @spec get(binary | %{id: binary}) :: nil | map()
  def get(%{id: id}), do: get(id)

  def get(id) when is_binary(id) do
    case :dets.lookup(table(), id) do
      [] ->
        nil

      [{^id, details}] ->
        details
    end
  end

  @doc """
  Delete existing chain process details
  """
  @spec delete(binary) :: :ok | {:error, term()}
  def delete(id), do: :dets.delete(table(), id)

  # get path to DETS file for storage chain process
  defp db_path() do
    :deployment_scope
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
