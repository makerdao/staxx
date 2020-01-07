defmodule Staxx.Testchain.EVM.Details do
  @moduledoc """
  EVM Details
  Contain list of EVM operational values
  """

  alias Staxx.Testchain
  alias Staxx.Testchain.EVM.Account

  @type t :: %__MODULE__{
          id: Testchain.evm_id(),
          coinbase: binary,
          accounts: [Account.t()],
          rpc_url: binary,
          ws_url: binary,
          gas_limit: pos_integer(),
          network_id: pos_integer()
        }

  @derive Jason.Encoder
  @enforce_keys [:id]
  defstruct id: nil,
            coinbase: "",
            accounts: [],
            rpc_url: "",
            ws_url: "",
            gas_limit: 6_000_000,
            network_id: Application.get_env(:testchain, :default_chain_id)
end

# defimpl Jason.Encoder, for: Staxx.Testchain.EVM.Details do
#   def encode(value, opts) do
#     value
#     |> Map.from_struct()
#     |> Jason.Encode.map(opts)
#   end
# end
