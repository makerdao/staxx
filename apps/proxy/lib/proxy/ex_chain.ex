defmodule Staxx.Proxy.ExChain do
  @moduledoc """
  ExTestchain application caller

  Module makes list of calls to `ex_testhcain` application runing on another node.
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

  @type ex_response :: term() | :ok | {:error, term()} | {:badrpc, term()}

  @doc """
  New unique id for chain
  """
  @callback unique_id(node :: node()) :: ex_response()

  @doc """
  List of available chains
  """
  @callback chain_list(node :: node()) :: ex_response()

  @doc """
  Get list of snapshots
  """
  @callback snapshot_list(node :: node(), chain_type :: Chain.evm_type()) ::
              ex_response()

  @doc """
  Get snapshot details by id
  """
  @callback get_snapshot(node :: node(), snapshot_id :: binary()) :: ex_response()

  @doc """
  Upload new snapshot to snapshot store
  """
  @callback upload_snapshot(
              node :: node(),
              snapshot_id :: binary,
              chain_type :: Chain.evm_type(),
              description :: binary
            ) :: {:ok, term} | ex_response()

  @doc """
  Remove snapshot by it's id from storage and delete file
  """
  @callback remove_snapshot(node :: node(), snapshot_id :: binary) :: ex_response()

  @doc """
  Start existing chain
  """
  @callback start_existing(node :: node(), id :: Chain.evm_id(), notify_pid :: nil | pid | module) ::
              ex_response()

  @doc """
  Start new chain using given configuration
  """
  @callback start(node :: node(), config :: map() | Chain.EVM.Config.t()) :: ex_response()

  @doc """
  Set new notify_pid for running chain
  """
  @callback new_notify_pid(node :: node(), id :: Chain.evm_id(), notify_pid :: pid | module) ::
              ex_response()

  @doc """
  Stop running chain by it's id
  """
  @callback stop(node :: node(), id :: Chain.evm_id()) :: ex_response()

  @doc """
  Clean stopped chain
  """
  @callback clean(node :: node(), id :: Chain.evm_id()) :: ex_response()

  @doc """
  Get chain details by it's id
  """
  @callback details(node :: node(), id :: Chain.evm_id()) :: ex_response()

  @doc """
  Take snapshot from chain
  """
  @callback take_snapshot(node :: node(), id :: Chain.evm_id(), description :: binary) ::
              ex_response()

  @doc """
  Revert snapshot for chain
  """
  @callback revert_snapshot(
              node :: node(),
              id :: Chain.evm_id(),
              snapshot :: Chain.Snapshot.Details.t()
            ) ::
              ex_response()

  @doc """
  Load snapshot by it's id
  """
  @callback load_snapshot(node :: node(), snapshot_id :: binary()) :: ex_response()

  @doc """
  Write external data to chain
  Later this data may be read using `read_external_data/2`

  Note: this data will be included into snapshot when you will try to make it for chain
  """
  @callback write_external_data(node :: node(), id :: Chain.evm_id(), data :: term) ::
              ex_response()

  @doc """
  Read external data that was stored by `ExChain.write_external_data/3`
  """
  @callback read_external_data(node :: node(), id :: Chain.evm_id()) :: ex_response()

  @doc """
  Versions for chains
  """
  @callback version(node :: node()) :: ex_response()

  @doc """
  New unique id for chain
  """
  @spec unique_id(node()) :: ex_response()
  def unique_id(node),
    do: adapter().unique_id(node)

  @doc """
  List of available chains
  """
  @spec chain_list(node()) :: ex_response()
  def chain_list(node),
    do: adapter().chain_list(node)

  @doc """
  List of snapshots
  """
  @spec snapshot_list(node(), Chain.evm_type()) :: ex_response()
  def snapshot_list(node, chain) when is_atom(chain),
    do: adapter().snapshot_list(node, chain)

  @doc """
  Get snapshot details by id
  """
  @spec get_snapshot(node(), binary()) :: ex_response()
  def get_snapshot(node, snapshot_id),
    do: adapter().get_snapshot(node, snapshot_id)

  @doc """
  Upload new snapshot to snapshot store
  """
  @spec upload_snapshot(node, binary, Chain.evm_type(), binary) :: {:ok, term} | ex_response()
  def upload_snapshot(node, snapshot_id, chain_type, description \\ ""),
    do: adapter().upload_snapshot(node, snapshot_id, chain_type, description)

  @doc """
  Remove snapshot by it's id from storage and delete file
  """
  @spec remove_snapshot(node(), binary) :: :ok | ex_response()
  def remove_snapshot(node, snapshot_id),
    do: adapter().remove_snapshot(node, snapshot_id)

  @doc """
  Start existing chain
  """
  @spec start_existing(node(), Chain.evm_id(), pid | module) :: ex_response()
  def start_existing(node, id, pid),
    do: adapter().start_existing(node, id, pid)

  @doc """
  Start new chain
  """
  @spec start(node(), map()) :: ex_response()
  def start(node, config) when is_map(config),
    do: adapter().start(node, config)

  @doc """
  Set new notify_pid
  """
  @spec new_notify_pid(node(), Chain.evm_id(), pid | module) :: ex_response()
  def new_notify_pid(node, id, pid),
    do: adapter().new_notify_pid(node, id, pid)

  @doc """
  Stoping chain
  """
  @spec stop(node(), Chain.evm_id()) :: ex_response()
  def stop(node, id),
    do: adapter().stop(node, id)

  @doc """
  Clean chain
  """
  @spec clean(node(), Chain.evm_id()) :: ex_response()
  def clean(node, id),
    do: adapter().clean(node, id)

  @doc """
  Load chain details
  """
  @spec details(node(), Chain.evm_id()) :: ex_response()
  def details(node, id),
    do: adapter().details(node, id)

  @doc """
  take snapshot from chain
  """
  @spec take_snapshot(node(), Chain.evm_id(), binary) :: ex_response()
  def take_snapshot(node, id, description \\ ""),
    do: adapter().take_snapshot(node, id, description)

  @doc """
  Revert snapshot for chain
  """
  @spec revert_snapshot(node(), Chain.evm_id(), Chain.Snapshot.Details.t()) ::
          ex_response()
  def revert_snapshot(node, id, snapshot),
    do: adapter().revert_snapshot(node, id, snapshot)

  @doc """
  Load snapshot by it's id
  """
  @spec load_snapshot(node(), binary()) :: ex_response()
  def load_snapshot(node, snapshot_id),
    do: adapter().load_snapshot(node, snapshot_id)

  @doc """
  Write external data to chain
  Note: this data will be included into snapshot
  """
  @spec write_external_data(node(), Chain.evm_id(), term) :: :ok | {:error, term}
  def write_external_data(node, id, data),
    do: adapter().write_external_data(node, id, data)

  @doc """
  Read external data that was stored by `ExChain.write_external_data/3`
  """
  @spec read_external_data(node(), Chain.evm_id()) :: {:ok, term} | {:error, term}
  def read_external_data(node, id),
    do: adapter().read_external_data(node, id)

  @doc """
  Versions for chains
  """
  @spec version(node()) :: ex_response()
  def version(node),
    do: adapter().version(node)

  @doc """
  Get configured ExChain adapter for application
  """
  def adapter() do
    Application.get_env(:proxy, :ex_chain_adapter) ||
      raise ArgumentError, "`:ex_chain_adapter` required to be configured"
  end

  @doc """
  Convert set of configs in map to chain configuration
  Actually picks required chain config keys
  """
  @spec to_config(map) :: map
  def to_config(config) when is_map(config),
    do: Map.take(config, @chain_config_keys)
end
