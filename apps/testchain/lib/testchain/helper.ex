defmodule Staxx.Testchain.Helper do
  @moduledoc """
  Testchain helper functions
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.EVM.Config
  alias Staxx.EventStream.Notification

  # List of keys chain need as config
  @evm_config_keys [
    :id,
    :type,
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
  Create new configuration for existing testchain.
  """
  @spec load_exitsing_chain_config(Testchain.evm_id()) :: Config.t()
  def load_exitsing_chain_config(id) do
    %Config{
      id: id,
      existing: true
    }
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

  @doc """
  Send chain started event
  """
  @spec notify_started(Testchain.evm_id(), map()) :: :ok
  def notify_started(id, details),
    do: Notification.notify(id, :started, details)

  @doc """
  Send error notification about testchain
  """
  @spec notify_error(Testchain.evm_id(), binary) :: :ok
  def notify_error(id, msg),
    do: Notification.notify(id, :error, %{message: msg})

  @doc """
  Send status changed event
  """
  @spec notify_status(Testchain.evm_id(), Testchain.EVM.status()) :: :ok
  def notify_status(id, status),
    do: Notification.notify(id, :status_changed, %{status: status})

  @doc """
  Write given structure into file
  """
  @spec write_term_to_file(binary, term) :: :ok | {:error, term()}
  def write_term_to_file(file, data) do
    file
    |> File.write(:erlang.term_to_binary(data))
  end

  @doc """
  Read term from given file and decode it to initial struct
  """
  @spec read_term_from_file(binary) :: {:ok, term} | {:error, term()}
  def read_term_from_file(file) do
    with true <- File.exists?(file),
         {:ok, content} <- File.read(file),
         res <- :erlang.binary_to_term(content, [:safe]) do
      {:ok, res}
    else
      err ->
        Logger.error(fn -> "Failed to read file #{file}: #{inspect(err)}" end)
        {:error, "failed to load data from #{file}"}
    end
  end

  ########################################
  # Private functions
  ########################################

  # Expands path like `~/something` to normal path
  defp fix_path!(%{db_path: db_path} = config),
    do: %Config{config | db_path: Path.expand(db_path)}
end
