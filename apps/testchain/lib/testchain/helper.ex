defmodule Staxx.Testchain.Helper do
  @moduledoc """
  Testchain helper functions
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.EVM
  alias Staxx.Testchain.EVM.Config
  alias Staxx.Testchain.Deployment.Result, as: DeploymentResult
  alias Staxx.Testchain.Deployment.Config, as: DeploymentConfig
  alias Staxx.Testchain.Deployment.Worker, as: DeploymentWorker
  alias Staxx.EventStream.Notification
  alias Staxx.Store.Models.Chain, as: ChainRecord
  alias Staxx.Store.Models.User, as: UserRecord

  # List of keys chain need as config
  @evm_config_keys [
    :id,
    :type,
    :email,
    :accounts,
    :network_id,
    :block_mine_time,
    :clean_on_stop,
    :description,
    :snapshot_id,
    :clean_on_stop,
    :deploy_ref,
    :deploy_step_id
  ]

  # Snapshots table name used as DETS file name
  @snapshots_table "snapshots"

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
      deploy_ref: Map.get(payload, "deploy_ref"),
      deploy_step_id: Map.get(payload, "deploy_step_id", 0)
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
  Loads configuration for existing testchain.
  """
  @spec load_exitsing_chain_config(Testchain.evm_id()) :: {:ok, Config.t()} | {:error, term}
  def load_exitsing_chain_config(id) do
    %Config{
      id: id
    }
    |> fill_missing_config!()
    |> Config.load()
    |> case do
      {:ok, config} ->
        {:ok, %Config{config | existing: true}}

      err ->
        err
    end
  end

  @doc """
  Store chain details in DB.
  Might show error in console but actuially erorr will be ignored
  """
  @spec store_chain_details(Testchain.evm_id(), EVM.Details.t()) :: :ok
  def store_chain_details(id, %EVM.Details{} = details) do
    # Storing chain details
    id
    |> ChainRecord.set(%{details: details})
    |> case do
      {:ok, _} ->
        Logger.debug(fn -> "#{id}: Stored chain details" end)

      {:error, err} ->
        Logger.error(fn ->
          "#{id}: Failed to store chain details: #{inspect(err)}"
        end)
    end
  end

  @doc """
  Store deployment result into DB.
  Might show error in console but actuially erorr will be ignored
  """
  @spec store_deployment_result(Testchain.evm_id(), DeploymentResult.t()) :: :ok
  def store_deployment_result(id, %DeploymentResult{} = result) do
    # Storing deployment result
    id
    |> ChainRecord.set(%{deployment: result})
    |> case do
      {:ok, _} ->
        Logger.debug(fn -> "#{id}: Stored deployment success details" end)

      {:error, err} ->
        Logger.error(fn ->
          "#{id}: Failed to store deployment result: #{inspect(err)}"
        end)
    end
  end

  @doc """
  Insert new chain record or updates existing one
  """
  @spec insert_or_update(Testchain.evm_id(), Config.t(), EVM.status()) ::
          {:ok, map()} | {:error, term}
  def insert_or_update(id, %Config{type: type, description: description} = config, status) do
    title =
      case description do
        "" ->
          id

        _ ->
          description
      end

    # Loading user from DB
    user_id =
      config
      |> Map.get(:email)
      |> get_user()
      |> case do
        nil ->
          nil

        %UserRecord{id: id} ->
          id
      end

    id
    |> ChainRecord.insert_or_update(%{
      node_type: Atom.to_string(type),
      user_id: user_id,
      title: title,
      config: config,
      status: Atom.to_string(status)
    })
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
  Run deployment worker for newly started EVM
  """
  @spec run_deployment(Testchain.evm_id(), GenServer.server(), binary, 1..9, map()) ::
          {:ok, term} | {:error, term}
  def run_deployment(id, evm_pid, git_ref, step_id, %{
        rpc_url: rpc_url,
        coinbase: coinbase
      }) do
    %DeploymentConfig{
      evm_pid: evm_pid,
      scope_id: id,
      step_id: step_id,
      git_ref: git_ref,
      rpc_url: rpc_url,
      coinbase: coinbase
    }
    |> DeploymentWorker.start_link()
  end

  def run_deployment(_state, _evm_pid, _git_ref, _step_id, _details),
    do: {:error, "No chain details exist"}

  @doc """
  Send chain started event
  """
  @spec notify(Testchain.evm_id(), Notification.event(), map()) :: :ok
  def notify(id, event, details),
    do: Notification.notify(id, event, details)

  @doc """
  Send chain started event
  """
  @spec notify_started(Testchain.evm_id(), map()) :: :ok
  def notify_started(id, details) do
    Notification.notify(id, :started, details)

    ChainRecord.set(id, %{details: details})
    :ok
  end

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
  def notify_status(id, status) do
    Notification.notify(id, :status_changed, %{status: status})
    # In case of ready status we need to send additional `:ready` event.
    if status == :ready do
      Notification.notify(id, :ready)
    end

    # Saving status change in DB
    ChainRecord.set_status(id, status)

    :ok
  end

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

  @doc """
  Returns path to DETS files directory
  """
  @spec dets_db_path() :: binary
  def dets_db_path() do
    :testchain
    |> Application.get_env(:dets_db_path)
    |> Path.expand()
  end

  @doc """
  Returns path to DETS file for snapshots table
  """
  @spec snapshots_table :: any()
  def snapshots_table() do
    dets_db_path()
    |> Path.join(@snapshots_table)
    |> String.to_atom()
  end

  ########################################
  # Private functions
  ########################################

  # Expands path like `~/something` to normal path
  defp fix_path!(%{db_path: db_path} = config),
    do: %Config{config | db_path: Path.expand(db_path)}

  # Load user from DB will create new one
  defp get_user(""), do: nil

  defp get_user(nil), do: nil

  defp get_user(email) do
    email
    |> UserRecord.by_email()
    |> case do
      nil ->
        %{email: email}
        |> UserRecord.create()
        |> case do
          {:ok, user} ->
            user

          {:error, err} ->
            Logger.error(fn -> "Failed to create user record for #{email}: #{inspect(err)}" end)
            nil
        end

      user ->
        user
    end
  end
end
