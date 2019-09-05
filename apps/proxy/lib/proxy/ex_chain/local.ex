defmodule Staxx.Proxy.ExChain.Local do
  @moduledoc """
  ExTestchain application caller

  Module makes list of calls to `ex_testhcain` application runing on another node.
  """

  @behaviour Staxx.Proxy.ExChain

  alias Staxx.Proxy.ExChain
  alias Staxx.ExChain.SnapshotManager

  require Logger

  @impl true
  def child_spec(), do: []

  @impl true
  def unique_id(_node),
    do: Staxx.ExChain.unique_id()

  @impl true
  def chain_list(_node),
    do: Staxx.ExChain.list()

  @impl true
  def snapshot_list(_node, chain) when is_atom(chain),
    do: SnapshotManager.by_chain(chain)

  @impl true
  def get_snapshot(_node, snapshot_id),
    do: SnapshotManager.by_id(snapshot_id)

  @impl true
  def upload_snapshot(_node, snapshot_id, chain_type, description \\ ""),
    do: SnapshotManager.upload(snapshot_id, chain_type, description)

  @impl true
  def remove_snapshot(_node, snapshot_id),
    do: SnapshotManager.remove(snapshot_id)

  @impl true
  def load_snapshot(_node, snapshot_id),
    do: SnapshotManager.by_id(snapshot_id)

  @impl true
  def start_existing(_node, id, pid),
    do: Staxx.ExChain.start_existing(id, pid)

  @impl true
  def start(_node, config) when is_map(config) do
    config
    |> ExChain.to_config()
    |> Staxx.ExChain.start()
  end

  @impl true
  def new_notify_pid(_node, id, pid),
    do: Staxx.ExChain.new_notify_pid(id, pid)

  @impl true
  def stop(_node, id),
    do: Staxx.ExChain.stop(id)

  @impl true
  def clean(_node, id),
    do: Staxx.ExChain.clean(id)

  @impl true
  def details(_node, id),
    do: Staxx.ExChain.details(id)

  @impl true
  def take_snapshot(_node, id, description \\ ""),
    do: Staxx.ExChain.take_snapshot(id, description)

  @impl true
  def revert_snapshot(_node, id, snapshot),
    do: Staxx.ExChain.revert_snapshot(id, snapshot)

  @impl true
  def write_external_data(_node, id, data),
    do: Staxx.ExChain.write_external_data(id, data)

  @impl true
  def read_external_data(_node, id),
    do: Staxx.ExChain.read_external_data(id)

  @impl true
  def version(_node),
    do: Staxx.ExChain.version()
end
