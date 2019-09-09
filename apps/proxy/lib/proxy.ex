defmodule Staxx.Proxy do
  @moduledoc """
  Proxy service functions
  """

  require Logger

  alias Staxx.Proxy.ExChain
  alias Staxx.Proxy.Chain
  alias Staxx.Proxy.NodeManager
  alias Staxx.Proxy.Chain.Storage
  alias Staxx.Proxy.Chain.Supervisor, as: ChainSupervisor

  @doc """
  Start new/existing chain
  """
  @spec start(binary | map()) :: {:ok, binary} | {:error, term()}
  def start(id) when is_binary(id) do
    case ChainSupervisor.start_chain(id, :existing) do
      :ok ->
        {:ok, id}

      {:ok, _} ->
        {:ok, id}

      err ->
        Logger.error("#{id}: Something wrong: #{inspect(err)}")
        {:error, "failed to start chain"}
    end
  end

  def start(config) when is_map(config) do
    with %{id: id} = config <- new_chain_config!(config),
         {:ok, _} <- ChainSupervisor.start_chain(config, :new) do
      {:ok, id}
    else
      {:error, err} ->
        {:error, err}

      err ->
        Logger.error("Failed to start EVM: #{inspect(err)}")
        {:error, "Unknown error"}
    end
  end

  @doc """
  Create new chain configuration for given node
  It will generate new uniq chain ID, will bind it to config
  also it will bind node and set `:clean_on_stop` to `false`.
  """
  @spec new_chain_config!(binary | map) :: map
  def new_chain_config!(config) do
    with {:node, node} when not is_nil(node) <- {:node, NodeManager.node()},
         _ <- Logger.debug(fn -> "Using node: #{node} for starting new chain" end),
         {:id, id} when is_binary(id) <- {:id, ExChain.unique_id(node)} do
      config
      |> Map.put(:id, id)
      |> Map.put(:node, node)
      |> Map.put(:clean_on_stop, false)
    else
      {:node, _} ->
        raise "No active ex_testchain node connected !"

      {:id, _} ->
        raise "Failed to generrate new id for EVM"
    end
  end

  @doc """
  Terminate chain
  """
  @spec stop(binary) :: :ok
  def stop(id) do
    id
    |> Chain.via_tuple()
    |> GenServer.cast(:stop)
  end

  @doc """
  Send take snapshot command to chain process
  """
  @spec take_snapshot(Staxx.ExChain.evm_id(), binary()) :: :ok | {:error, term()}
  def take_snapshot(id, description \\ "") do
    id
    |> Chain.via_tuple()
    |> GenServer.call({:take_snapshot, description})
  end

  @doc """
  Will send command to the chain to revert snapshot.
  `:ok` will mean that reverting snapshot process started you have to wait for an event
  about complition
  """
  @spec revert_snapshot(Staxx.ExChain.evm_id(), binary) :: :ok | {:error, term()}
  def revert_snapshot(id, snapshot_id) do
    id
    |> Chain.via_tuple()
    |> GenServer.call({:revert_snapshot, snapshot_id})
  end

  @doc """
  Load snapshot details
  """
  @spec get_snapshot(binary) :: map() | ExChain.ex_response()
  def get_snapshot(snapshot_id) do
    NodeManager.node()
    |> ExChain.get_snapshot(snapshot_id)
  end

  @doc """
  Binding to remove snapshot from ex_testchain
  """
  @spec remove_snapshot(binary) :: :ok | ExChain.ex_response()
  def remove_snapshot(snapshot_id) do
    NodeManager.node()
    |> ExChain.remove_snapshot(snapshot_id)
  end

  @doc """
  Alias for uploading snapshot to storage
  File has to be already placed to snapshot store
  """
  @spec upload_snapshot(binary, Staxx.ExChain.evm_type(), binary) :: {:ok, term} | ExChain.ex_response()
  def upload_snapshot(snapshot_id, chain_type, description \\ "") do
    NodeManager.node()
    |> ExChain.upload_snapshot(snapshot_id, chain_type, description)
  end

  @doc """
  Remove all details about chain by id
  """
  @spec clean(binary) :: :ok | {:error, binary}
  def clean(id) do
    with {:node, node} when not is_nil(node) <- {:node, NodeManager.node()},
         :ok <- ExChain.clean(node, id),
         _ <- Storage.delete(id) do
      :ok
    else
      {:node, _} ->
        {:error, "No active ex_testchain node connected !"}

      err ->
        Logger.error("Failed to clean up chain #{id} details #{inspect(err)}")
        {:error, "failed to clean up chain #{id} details"}
    end
  end

  @doc """
  Load list of snapshots from random ex_testchain node
  """
  @spec snapshot_list(Staxx.ExChain.evm_type()) :: [map()]
  def snapshot_list(chain_type) do
    with {:node, node} when not is_nil(node) <- {:node, NodeManager.node()},
         list <- ExChain.snapshot_list(node, chain_type),
         list <- Enum.map(list, &Map.from_struct/1) do
      list
    else
      err ->
        Logger.error("Failed to load list of snapshots for #{chain_type} err: #{inspect(err)}")

        []
    end
  end

  @doc """
  Get details about chain by it's id
  """
  @spec details(binary) :: nil | map()
  def details(id), do: Storage.get(id)

  @doc """
  List of all avaialbe chains
  """
  @spec chain_list() :: [map()]
  def chain_list(), do: Storage.all()

  @doc """
  Get chains version
  """
  @spec version() :: binary | {:error, term()}
  def version() do
    NodeManager.node()
    |> ExChain.version()
  end
end
