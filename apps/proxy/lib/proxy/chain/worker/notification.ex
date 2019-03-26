defmodule Proxy.Chain.Worker.Notification do
  @moduledoc """
  Default chain worker notification that might be sent by system
  """
  @type t :: %__MODULE__{id: binary, event: binary | atom, data: term}

  @derive Jason.Encoder
  defstruct id: nil, event: nil, data: %{}

  @doc """
  Send notification to event bus
  """
  @spec send_to_event_bus(%__MODULE__{}) :: :ok
  def send_to_event_bus(%__MODULE__{id: id} = notification) do
    Proxy.EventBus.Broadcaster.notify({"chain.#{id}", notification})
  end

  @doc """
  Send custom notification to event bus
  """
  @spec send_to_event_bus(binary, binary, term) :: :ok
  def send_to_event_bus(id, event, data \\ %{}) do
    %__MODULE__{id: id, event: event, data: data}
    |> send_to_event_bus()
  end
end

require Protocol

Protocol.derive(Jason.Encoder, Chain.EVM.Process)
Protocol.derive(Jason.Encoder, Chain.EVM.Account)
Protocol.derive(Jason.Encoder, Chain.EVM.Notification)
