defmodule Staxx.Testchain.EVM.Config do
  @moduledoc """
  Default start configuration for new EVM.

  Options:
  - `type` - EVM type. (Default: `:ganache`)
  - `id` - Random unique internal process identificator. Example: `"11296068888839073704"`. If empty system will generate it automatically
  - `existing` - Identifies if we need to start already existing chain. In that case all other options except `id` will be ignored.
  - `network_id` - Network ID (Default: `Application.get_env(:testchain, :default_chain_id)`)
  - `db_path` - Specify a path to a directory to save the chain database
  - `block_mine_time` - Block period to use in developer mode (0 = mine only if transaction pending) (default: 0)
  - `gas_limit` - The block gas limit (defaults to `9000000000000`)
  - `accounts` - How many accoutn should be created on start (Default: `1`)
  - `clean_on_stop` - Clean up `db_path` after chain is stopped. (Default: `false`)
  - `description` - Chain description for storage
  - `container_name` - EVM container name.
  - `snapshot_id` - Snapshot ID that should be loaded on chain start
  - `deploy_ref` - Deployment scripts git ref
  - `deploy_step_id` - Deployment scripts step/scenario id
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.Helper

  # File name where cnofig will be writen
  @config_file_name "chain.cfg"

  @type t :: %__MODULE__{
          type: Testchain.evm_type(),
          id: Testchain.evm_id() | nil,
          existing: boolean(),
          network_id: non_neg_integer(),
          db_path: binary(),
          block_mine_time: non_neg_integer(),
          gas_limit: pos_integer(),
          accounts: non_neg_integer(),
          clean_on_stop: boolean(),
          description: binary,
          container_name: binary,
          snapshot_id: nil | binary,
          deploy_ref: binary,
          deploy_step_id: pos_integer
        }

  @derive Jason.Encoder
  defstruct type: :ganache,
            id: nil,
            existing: false,
            network_id: Application.get_env(:testchain, :default_chain_id, 999),
            db_path: "",
            block_mine_time: 0,
            gas_limit: 9_000_000_000_000,
            accounts: 1,
            clean_on_stop: false,
            description: "",
            container_name: "",
            snapshot_id: nil,
            deploy_ref: "",
            deploy_step_id: 0

  @doc """
  Check if configuration has deployment task to perform
  """
  @spec has_deployment?(t()) :: boolean
  def has_deployment?(%__MODULE__{existing: true}),
    do: false

  def has_deployment?(%__MODULE__{deploy_step_id: deploy_step_id}),
    do: deploy_step_id != 0

  @doc """
  Store configuration in testhcian `db_path`.
  """
  @spec store(t()) :: :ok | {:error, term}
  def store(%__MODULE__{db_path: ""}),
    do: {:error, "no db_path exist in config"}

  def store(%__MODULE__{db_path: db_path} = config) do
    db_path
    |> Path.join(@config_file_name)
    |> Helper.write_term_to_file(config)
  end

  @doc """
  Load configuration from given path
  """
  @spec load(t() | binary) :: {:ok, t()} | {:error, term}
  def load(%__MODULE__{db_path: ""}),
    do: {:error, "no db_path exist in config for loading"}

  def load(%__MODULE__{db_path: db_path}),
    do: load(db_path)

  def load(db_path) do
    db_path
    |> Path.join(@config_file_name)
    |> Helper.read_term_from_file()
  end
end
