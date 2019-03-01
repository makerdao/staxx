defmodule Proxy.EventBus.Consumer do
  @moduledoc """
  The GenEvent handler implementation is a simple consumer.
  It will receive all events from other pars of the system and resent them into Bus
  """

  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok)
  end

  # Callbacks

  def init(:ok) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.
    {:consumer, :ok, subscribe_to: [Proxy.EventBus.Broadcaster]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      Proxy.EventBus.Nats.push(event)
    end

    {:noreply, [], state}
  end
end
