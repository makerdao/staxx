defmodule Staxx.Store.EventHandler do
  @moduledoc """
  Main module for handling chain events
  """
  use GenServer
  require Logger
  alias Staxx.EventStream

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Logger.debug(fn -> "Starting Event handler for Staxx" end)
    :ok = EventStream.subscribe({__MODULE__, ["chain"]})
    {:ok, []}
  end

  def terminate(_reason, _state),
    do: EventStream.unsubscribe(__MODULE__)

  def process({:chain, id}) do
    case EventStream.fetch_event_data({:chain, id}) do
      %{id: chain_id, event: _event, data: _data} = msg ->
        Logger.debug(fn -> "#{chain_id}: Notification: #{inspect(msg, pretty: true)}" end)
        EventStream.mark_as_completed({__MODULE__, :chain, id})

      _ ->
        :ok
    end
  end
end
