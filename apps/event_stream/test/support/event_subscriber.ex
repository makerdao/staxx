defmodule Staxx.EventStream.Test.EventSubscriber do
  @moduledoc """
  Helper module for handling events
  """

  use GenServer

  alias EventBus.Model.Event

  @doc false
  def start_link(state),
    do: GenServer.start_link(__MODULE__, state, name: __MODULE__)

  @doc false
  def init(pid),
    do: {:ok, pid}

  def handle_cast(event_shadow, pid) do
    event_shadow
    |> EventBus.fetch_event()
    |> case do
      %Event{topic: topic, data: data, transaction_id: nil} ->
        send(pid, {topic, data})

      %Event{topic: topic, data: %{msg: msg}, transaction_id: transaction_id} ->
        send(pid, {topic, msg, transaction_id})

      _ ->
        :ok
    end

    EventBus.mark_as_completed({__MODULE__, event_shadow})
    {:noreply, pid}
  end

  def process(event_shadow),
    do: GenServer.cast(__MODULE__, event_shadow)
end
