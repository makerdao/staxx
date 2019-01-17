defmodule Proxy.ExChain do
  @moduledoc """
  Chain caller
  """

  @doc """
  List of available chains
  """
  def chain_list(), do: call(Storage, :list)

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
  Versions for chains
  """
  def version(), do: call(Chain, :version)

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
