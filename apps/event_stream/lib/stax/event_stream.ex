defmodule Staxx.EventStream do
  @moduledoc """
  Documentation for Staxx.EventStream.
  """

  alias EventBus.Model.Event

  def subscribe(subs),
    do: EventBus.subscribe(subs)

  def mark_as_completed(msg),
    do: EventBus.mark_as_completed(msg)

  def mark_as_skipped(msg),
    do: EventBus.mark_as_skipped(msg)

  def fetch_event_data(msg),
    do: EventBus.fetch_event_data(msg)

  def dispatch(%{id: id} = msg) do
    %Event{
      id: UUID.uuid4(),
      transaction_id: id,
      topic: :chain,
      data: msg
    }
    |> EventBus.notify()
  end

  def dispatch({topic, msg}) do
    %Event{
      id: UUID.uuid4(),
      topic: topic,
      data: msg
    }
    |> EventBus.notify()
  end
end
