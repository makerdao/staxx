defmodule EventBus do
  @moduledoc """
  Documentation for EventBus.
  """

  @doc """
  Dispatches an event into event bus
  """
  @spec dispatch(map) :: :ok
  def dispatch(%{id: id} = event) when is_binary(id),
    do: EventBus.Broadcaster.notify({"chain.#{id}", event})

  @doc """
  Subscribe caller to given topic
  Event will be sent as Erlang message in format:
  ```elixir
  %{id: "stack/chain-id", event: "event-name", data: %{}}
  ```
  """
  @spec subscribe(binary) :: :ok
  def subscribe(topic) when is_binary(topic) do
    {:ok, _} = Registry.register(LocalPubSub, topic, [])
    :ok
  end

  @doc """
  Global topic name.
  For local subscribers all events will glow through this topic.
  """
  @spec global() :: binary
  def global(), do: "global"
end
