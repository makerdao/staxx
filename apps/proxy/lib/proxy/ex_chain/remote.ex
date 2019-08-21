defmodule Staxx.Proxy.ExChain.Remote do
  @moduledoc """
  ExTestchain application caller

  Module makes list of calls to `ex_testhcain` application runing on another node.
  """

  @behaviour Staxx.Proxy.ExChain

  alias Staxx.Proxy.ExChain

  require Logger

  @impl true
  def child_spec(), do: []

  @impl true
  def unique_id(node),
    do: call(node, Chain, :unique_id)

  @impl true
  def chain_list(node), do: call(node, Chain, :list)

  @impl true
  def snapshot_list(node, chain) when is_atom(chain),
    do: call(node, Chain.SnapshotManager, :by_chain, [chain])

  @impl true
  def get_snapshot(node, snapshot_id),
    do: call(node, Chain.SnapshotManager, :by_id, [snapshot_id])

  @impl true
  def upload_snapshot(node, snapshot_id, chain_type, description \\ ""),
    do: call(node, Chain.SnapshotManager, :upload, [snapshot_id, chain_type, description])

  @impl true
  def remove_snapshot(node, snapshot_id),
    do: call(node, Chain.SnapshotManager, :remove, [snapshot_id])

  @impl true
  def start_existing(node, id, pid),
    do: call(node, Chain, :start_existing, [id, pid])

  @impl true
  def start(node, config) when is_map(config),
    do: call(node, Chain, :start, [ExChain.to_config(config)])

  @impl true
  def new_notify_pid(node, id, pid),
    do: call(node, Chain, :new_notify_pid, [id, pid])

  @impl true
  def stop(node, id),
    do: call(node, Chain, :stop, [id])

  @impl true
  def clean(node, id),
    do: call(node, Chain, :clean, [id])

  @impl true
  def details(node, id),
    do: call(node, Chain, :details, [id])

  @impl true
  def take_snapshot(node, id, description \\ ""),
    do: call(node, Chain, :take_snapshot, [id, description])

  @impl true
  def revert_snapshot(node, id, snapshot),
    do: call(node, Chain, :revert_snapshot, [id, snapshot])

  @impl true
  def load_snapshot(node, snapshot_id),
    do: call(node, Chain.SnapshotManager, :by_id, [snapshot_id])

  @impl true
  def write_external_data(node, id, data),
    do: call(node, Chain, :write_external_data, [id, data])

  @impl true
  def read_external_data(node, id),
    do: call(node, Chain, :read_external_data, [id])

  @impl true
  def version(node),
    do: call(node, Chain, :version)

  # Make an RPC call to ex_testchain application
  defp call(node, module, function, params \\ [])

  defp call(nil, module, function, params) do
    Logger.error("No connected node for calling #{module} - #{function} [#{inspect(params)}]")
    {:error, :no_active_node}
  end

  defp call(node, module, function, params),
    do: :rpc.call(node, module, function, params)
end
