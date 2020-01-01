defmodule Staxx.Testchain.Helper do
  @moduledoc """
  Testchain helper functions
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.EVM.Config

  # List of keys chain need as config
  @evm_config_keys [
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
  Convert payload (from POST) to valid chain config
  """
  @spec config_from_payload(map) :: map
  def config_from_payload(payload) when is_map(payload) do
    %{
      type: String.to_atom(Map.get(payload, "type", "ganache")),
      network_id: Map.get(payload, "network_id", 999),
      accounts: Map.get(payload, "accounts", 1),
      block_mine_time: Map.get(payload, "block_mine_time", 0),
      clean_on_stop: Map.get(payload, "clean_on_stop", false),
      description: Map.get(payload, "description", ""),
      snapshot_id: Map.get(payload, "snapshot_id"),
      deploy_tag: Map.get(payload, "deploy_tag"),
      step_id: Map.get(payload, "step_id", 0)
    }
  end

  @doc """
  Updates geven EVM configuration
  It will generate new uniq chain ID and bind it to config.
  """
  @spec generate_id!(binary | map) :: binary | map
  def generate_id!(config) when is_map(config) do
    config
    |> Map.put(:id, Testchain.unique_id())
  end

  def generate_id!(config),
    do: config

  @doc """
  Convert set of configs from givem map to `Staxx.Testchain.EVM.Config`
  Actually picks required by evm config keys and convert map to struct
  """
  @spec to_evm_config(map) :: map
  def to_evm_config(config) when is_map(config) do
    config = Map.take(config, @evm_config_keys)

    Config
    |> Kernel.struct(config)
    |> fill_missing_config!()
  end

  @doc """
  Fill missing config values like `db_path` or others that are not required
  """
  @spec fill_missing_config!(Config.t()) :: Config.t()
  def fill_missing_config!(%Config{id: id, db_path: ""} = config) do
    path = Testchain.evm_db_path(id)
    Logger.debug("#{id}: Chain DB path not configured will generate #{path}")
    fill_missing_config!(%Config{config | db_path: path})
  end

  def fill_missing_config!(%Config{} = config),
    do: fix_path!(config)

  # Expands path like `~/something` to normal path
  # This function is handler for `output: nil`
  defp fix_path!(%{db_path: db_path, output: nil} = config),
    do: %Config{config | db_path: Path.expand(db_path)}

  defp fix_path!(%{db_path: db_path, output: ""} = config),
    do: fix_path!(%Config{config | output: "#{db_path}/out.log"})

  defp fix_path!(%{db_path: db_path, output: output} = config),
    do: %Config{config | db_path: Path.expand(db_path), output: Path.expand(output)}
end
