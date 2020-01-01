defmodule Staxx.Testchain.EVM.Process do
  @moduledoc """
  EVM Process identifier
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

  @enforce_keys [:id]
  defstruct id: nil,
            coinbase: "",
            accounts: [],
            rpc_url: "",
            ws_url: "",
            gas_limit: 6_000_000,
            network_id: Application.get_env(:ex_chain, :default_chain_id)
end

defimpl Jason.Encoder, for: Staxx.Testchain.EVM.Process do
  def encode(value, opts) do
    value
    |> Map.from_struct()
    |> Jason.Encode.map(opts)
  end
end
