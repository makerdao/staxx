defmodule Proxy.Chain.Worker.Notification do
  @moduledoc """
  Default chain worker notification that might be sent by system
  """
  @type t :: %__MODULE__{id: binary, event: binary | atom, data: term}

  @derive Jason.Encoder
  defstruct id: nil, event: nil, data: %{}
end

require Protocol

Protocol.derive(Jason.Encoder, Chain.EVM.Process)
Protocol.derive(Jason.Encoder, Chain.EVM.Account)
Protocol.derive(Jason.Encoder, Chain.EVM.Notification)
