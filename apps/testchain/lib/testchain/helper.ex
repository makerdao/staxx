defmodule Staxx.Testchain.Helper do
  @moduledoc """
  Testchain helper functions
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.EVM
  alias Staxx.Testchain.EVM.Config
  alias Staxx.Testchain.{SnapshotManager, SnapshotDetails}
  alias Staxx.Testchain.Deployment.Result, as: DeploymentResult
  alias Staxx.Testchain.Deployment.Config, as: DeploymentConfig
  alias Staxx.Testchain.Deployment.Worker, as: DeploymentWorker
  alias Staxx.EventStream.Notification
  alias Staxx.Store.Models.Chain, as: ChainRecord
  alias Staxx.Store.Models.User, as: UserRecord
  alias Staxx.Utils

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

  # List of EVM statuses that should be propagated as standalone events
  @propagated_statuses [:ready, :terminated]

  # File name where all details will be written on snapshoting
  @dump_file "chain_dump.bin"

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
  Merges config loaded from ChainRecord (will be presented as map)
  And current evm config.
  """
  @spec merge_snapshoted_config(map, Config.t()) :: Config.t()
  def merge_snapshoted_config(cfg, %Config{} = config) when is_map(cfg) do
    %Config{
      config
      | accounts: Map.get(cfg, "accounts", 1),
        gas_limit: Map.get(cfg, "gas_limit", 9_000_000_000_000),
        network_id: Map.get(cfg, "network_id", 999),
        deploy_ref: Map.get(cfg, "deploy_ref", ""),
        deploy_step_id: Map.get(cfg, "deploy_step_id", 0),
        block_mine_time: Map.get(cfg, "block_mine_time", 0)
    }
  end

  def merge_snapshoted_config(_cfg, %Config{} = config),
    do: config

  @doc """
  Merges current EVM config with config/details/deployment that will be loaded from dump file.
  Dump file have to be into `db_path` and it's path shuold be combination of `Path.join(db_path, file_name)
  """
  @spec merge_record_from_dump(Config.t()) :: Config.t()
  def merge_record_from_dump(%Config{db_path: db_path} = config) do
    db_path
    |> Path.join(@dump_file)
    |> read_term_from_file()
    |> case do
      {:ok, %ChainRecord{config: cfg} = record} ->
        # Rewriting evm configuration
        config = merge_snapshoted_config(cfg, config)
        # Updating EVM record in DB
        ChainRecord.rewrite(config.id, %ChainRecord{record | config: config})
        Logger.debug(fn -> "#{config.id}: Updated details for chain." end)

        # Removing dump file
        db_path
        |> Path.join(@dump_file)
        |> File.rm()

        # Returning mutated config
        config

      _ ->
        Logger.warn(fn -> "#{config.id}: Failed to get chain record dump. Will irnore." end)
        # Returning non mutated config
        config
    end
  end

  @doc """
  Makes snapshot for given EVM configuration.

  Also will dump EVM details from DB to dump file
  """
  @spec do_snapshot(Config.t(), binary) :: {:ok, SnapshotDetails.t()} | {:error, term}
  def do_snapshot(%Config{id: id, db_path: db_path, type: type}, description) do
    # Loading chain details
    id
    |> ChainRecord.get()
    |> case do
      %ChainRecord{} = chain_dump ->
        # Writing it to snapshot folder
        db_path
        |> Path.join(@dump_file)
        |> write_term_to_file(chain_dump)

      nil ->
        Logger.error(fn -> "#{id}: No EVM details loaded from db for snapshot" end)
    end

    # Executing snapshot
    db_path
    |> SnapshotManager.make_snapshot(type, description)
    |> case do
      {:ok, details} ->
        # Storing all snapshots
        SnapshotManager.store(details)
        Logger.debug("#{id}: Snapshot made, details: #{inspect(details)}")

        # Removing dump file
        db_path
        |> Path.join(@dump_file)
        |> File.rm()

        {:ok, details}

      err ->
        err
    end
  end

  @doc """
  Will check DB details, extract snapshot details to given path
  and werite data in DB by `ChainRecord.id`
  """
  @spec extract_snapshot(binary, Config.t()) :: :ok | {:error, term}
  def extract_snapshot(snapshot_id, %Config{db_path: db_path} = config) do
    try do
      snapshot_id
      |> SnapshotManager.by_id()
      |> case do
        nil ->
          {:error, "No snapshot exist with id #{snapshot_id}"}

        %SnapshotDetails{} = details ->
          SnapshotManager.restore_snapshot(details, db_path)
      end
    rescue
      err ->
        Logger.error(fn -> "#{config.id}: Failed to extract snapshot: #{inspect(err)}" end)
        {:error, "failed to extract snapshot"}
    end
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
  def run_deployment(id, evm_pid, git_ref, step_id, rpc_url, coinbase) do
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
    ChainRecord.set(id, %{details: details})

    Notification.notify(id, :started, details)
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
    # Saving status change in DB
    ChainRecord.set_status(id, status)

    # In case of need to propagate EVM status as standalone event.
    # Status will be propagated as event.
    if status in @propagated_statuses do
      Notification.notify(id, status)
    end

    Notification.notify(id, :status_changed, %{status: status})
  end

  @doc """
  Write given structure into file
  """
  @spec write_term_to_file(binary, term) :: :ok | {:error, term()}
  def write_term_to_file(file, data) do
    file
    |> Utils.file_write(:erlang.term_to_binary(data))
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
      false ->
        Logger.error(fn -> "Failed to read file #{file}: no file exist" end)
        {:error, "failed to load data from #{file}"}

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
