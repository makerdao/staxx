defmodule Proxy.ExChain do
  @moduledoc """
  Chain caller
  """

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

  @doc """
  New unique id for chain
  """
  def unique_id(),
    do: call(Chain, :unique_id)

  @doc """
  List of available chains
  """
  def chain_list(), do: call(Chain, :list)

  @doc """
  List of snapshots
  """
  def snapshot_list(chain) when is_atom(chain),
    do: call(Chain.SnapshotManager, :by_chain, [chain])

  @doc """
  Get snapshot details by id
  """
  def get_snapshot(snapshot_id),
    do: call(Chain.SnapshotManager, :by_id, [snapshot_id])

  @doc """
  Start existing chain
  """
  def start_existing(id, pid),
    do: call(Chain, :start_existing, [id, pid])

  @doc """
  Start new chain
  """
  def start(config) when is_map(config),
    do: call(Chain, :start, [to_config(config)])

  @doc """
  Set new notify_pid
  """
  def new_notify_pid(id, pid),
    do: call(Chain, :new_notify_pid, [id, pid])

  @doc """
  Stoping chain
  """
  def stop(id),
    do: call(Chain, :stop, [id])

  @doc """
  Clean chain
  """
  def clean(id),
    do: call(Chain, :clean, [id])

  @doc """
  Load chain details 
  """
  def details(id),
    do: call(Chain, :details, [id])

  @doc """
  take snapshot from chain
  """
  def take_snapshot(id, description \\ ""),
    do: call(Chain, :take_snapshot, [id, description])

  @doc """
  Revert snapshot for chain
  """
  def revert_snapshot(id, snapshot),
    do: call(Chain, :revert_snapshot, [id, snapshot])

  @doc """
  Load snapshot by it's id
  """
  def load_snapshot(snapshot_id),
    do: call(Chain.SnapshotManager, :by_id, [snapshot_id])

  @doc """
  Versions for chains
  """
  def version(), do: call(Chain, :version)

  @doc """
  Convert to chain configuration
  """
  def to_config(config) when is_map(config),
    do: Map.take(config, @chain_config_keys)

  @doc """
  Make an RPC call to ex_testchain application
  """
  @spec call(module, atom, [term()]) :: term() | {:error, term()} | {:badrpc, term()}
  def call(module, function, params \\ []) do
    case Proxy.NodeManager.chain() do
      nil ->
        {:error, :no_chain_connected}

      node ->
        :rpc.call(node, module, function, params)
    end
  end
end
