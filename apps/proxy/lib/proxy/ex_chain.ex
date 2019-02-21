defmodule Proxy.ExChain do
  @moduledoc """
  Chain caller
  """

  require Logger

  # List of keys chain need as config
  @chain_config_keys [
    :id,
    :type,
    :notify_pid,
    :accounts,
    :network_id,
    :block_mine_time,
    :clean_on_stop,
    :description,
    :snapshot_id,
    :clean_on_stop
  ]

  @type ex_response :: term() | {:error, term()} | {:badrpc, term()}

  @doc """
  New unique id for chain
  """
  @spec unique_id(node()) :: Proxy.ExChain.ex_response()
  def unique_id(node),
    do: call(node, Chain, :unique_id)

  @doc """
  List of available chains
  """
  @spec chain_list(node()) :: Proxy.ExChain.ex_response()
  def chain_list(node), do: call(node, Chain, :list)

  @doc """
  List of snapshots
  """
  @spec snapshot_list(node(), Chain.evm_type()) :: Proxy.ExChain.ex_response()
  def snapshot_list(node, chain) when is_atom(chain),
    do: call(node, Chain.SnapshotManager, :by_chain, [chain])

  @doc """
  Get snapshot details by id
  """
  @spec get_snapshot(node(), binary()) :: Proxy.ExChain.ex_response()
  def get_snapshot(node, snapshot_id),
    do: call(node, Chain.SnapshotManager, :by_id, [snapshot_id])

  @doc """
  Start existing chain
  """
  @spec start_existing(node(), Chain.evm_id(), pid | module) :: Proxy.ExChain.ex_response()
  def start_existing(node, id, pid),
    do: call(node, Chain, :start_existing, [id, pid])

  @doc """
  Start new chain
  """
  @spec start(node(), map()) :: Proxy.ExChain.ex_response()
  def start(node, config) when is_map(config),
    do: call(node, Chain, :start, [to_config(config)])

  @doc """
  Set new notify_pid
  """
  @spec new_notify_pid(node(), Chain.evm_id(), pid | module) :: Proxy.ExChain.ex_response()
  def new_notify_pid(node, id, pid),
    do: call(node, Chain, :new_notify_pid, [id, pid])

  @doc """
  Stoping chain
  """
  @spec stop(node(), Chain.evm_id()) :: Proxy.ExChain.ex_response()
  def stop(node, id),
    do: call(node, Chain, :stop, [id])

  @doc """
  Clean chain
  """
  @spec clean(node(), Chain.evm_id()) :: Proxy.ExChain.ex_response()
  def clean(node, id),
    do: call(node, Chain, :clean, [id])

  @doc """
  Load chain details 
  """
  @spec details(node(), Chain.evm_id()) :: Proxy.ExChain.ex_response()
  def details(node, id),
    do: call(node, Chain, :details, [id])

  @doc """
  take snapshot from chain
  """
  @spec take_snapshot(node(), Chain.evm_id(), binary) :: Proxy.ExChain.ex_response()
  def take_snapshot(node, id, description \\ ""),
    do: call(node, Chain, :take_snapshot, [id, description])

  @doc """
  Revert snapshot for chain
  """
  @spec revert_snapshot(node(), Chain.evm_id(), Chain.Snapshot.Details.t()) ::
          Proxy.ExChain.ex_response()
  def revert_snapshot(node, id, snapshot),
    do: call(node, Chain, :revert_snapshot, [id, snapshot])

  @doc """
  Load snapshot by it's id
  """
  @spec load_snapshot(node(), binary()) :: Proxy.ExChain.ex_response()
  def load_snapshot(node, snapshot_id),
    do: call(node, Chain.SnapshotManager, :by_id, [snapshot_id])

  @doc """
  Versions for chains
  """
  @spec version(node()) :: Proxy.ExChain.ex_response()
  def version(node), do: call(node, Chain, :version)

  @doc """
  Convert to chain configuration
  """
  def to_config(config) when is_map(config),
    do: Map.take(config, @chain_config_keys)

  @doc """
  Make an RPC call to ex_testchain application
  """
  @spec call(node(), module, atom, [term()]) :: term() | {:error, term()} | {:badrpc, term()}
  def call(node, module, function, params \\ [])

  def call(nil, module, function, params) do
    Logger.error("No connected node for calling #{module} - #{function} [#{inspect(params)}]")
    {:error, :no_active_node}
  end

  def call(node, module, function, params),
    do: :rpc.call(node, module, function, params)
end
