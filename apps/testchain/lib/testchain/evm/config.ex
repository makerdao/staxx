defmodule Staxx.Testchain.EVM.Config do
  @moduledoc """
  Default start configuration for new EVM.

  Options:
  - `type` - EVM type. (Default: `:ganache`)
  - `id` - Random unique internal process identificator. Example: `"11296068888839073704"`. If empty system will generate it automatically
  - `network_id` - Network ID (Default: `Application.get_env(:deployment, :default_chain_id)`)
  - `db_path` - Specify a path to a directory to save the chain database
  - `block_mine_time` - Block period to use in developer mode (0 = mine only if transaction pending) (default: 0)
  - `gas_limit` - The block gas limit (defaults to `9000000000000`)
  - `accounts` - How many accoutn should be created on start (Default: `1`)
  - `notify_pid` - Internal process id that will be notified on some chain events
  - `output` - Path to logs file. If empty string passing logs will be stored into `db_path <> /out.log`. To disable logging pass `nil`
  - `clean_on_stop` - Clean up `db_path` after chain is stopped. (Default: `false`)
  - `description` - Chain description for storage
  - `snapshot_id` - Snapshot ID that should be loaded on chain start

  """

  require Logger

  alias Staxx.Testchain

  @type t :: %__MODULE__{
          type: Testchain.evm_type(),
          id: Testchain.evm_id() | nil,
          network_id: non_neg_integer(),
          db_path: binary(),
          block_mine_time: non_neg_integer(),
          gas_limit: pos_integer(),
          accounts: non_neg_integer(),
          notify_pid: nil | pid(),
          clean_on_stop: boolean(),
          description: binary,
          snapshot_id: nil | binary
        }

  defstruct type: :ganache,
            id: nil,
            network_id: Application.get_env(:ex_chain, :default_chain_id, 999),
            db_path: "",
            block_mine_time: 0,
            gas_limit: 9_000_000_000_000,
            accounts: 1,
            output: "",
            notify_pid: nil,
            clean_on_stop: false,
            description: "",
            snapshot_id: nil
end
