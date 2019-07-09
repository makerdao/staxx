defmodule Stax.EventStream.NatsPublisher do
  @moduledoc """
  Nats handler.
  """
  use GenServer

  require Logger
  alias Stax.EventStream

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(_) do
    nats_config = Application.get_env(:event_stream, :nats)
    {:ok, conn} = Gnat.start_link(nats_config)
    Logger.debug("Connected to Nats.io with config #{inspect(nats_config)}")

    :ok = EventStream.subscribe({__MODULE__, [".*"]})
    Logger.debug("Subscribed to EventBus topics")
    {:ok, conn}
  end

  @doc false
  def handle_call({:sub, topic}, {pid, _}, conn) do
    case Gnat.sub(conn, pid, topic) do
      {:ok, _sub} ->
        {:reply, :ok, conn}

      rep ->
        {:reply, rep, conn}
    end
  end

  @doc false
  def handle_cast({:push, {topic, event}}, conn) when is_binary(topic) do
    Gnat.pub(conn, topic, Jason.encode!(event), [])
    {:noreply, conn}
  end

  @doc false
  def handle_cast({:push, event}, conn) do
    Logger.error("Wrong topic received #{inspect(event)}")
    {:noreply, conn}
  end

  @doc false
  def handle_cast({:event, :chain, id}, conn) do
    case EventStream.fetch_event_data({:chain, id}) do
      %{id: chain_id, event: _event, data: _data} = msg ->
        handle_cast({:push, {"chain.#{chain_id}", msg}}, conn)
        EventStream.mark_as_completed({__MODULE__, :chain, id})
        {:noreply, conn}

      _ ->
        {:noreply, conn}
    end
  end

  @doc false
  def handle_cast({:event, :docker, id}, conn) do
    msg = EventStream.fetch_event_data({:docker, id})
    topic = Application.get_env(:event_stream, :nats_docker_events_topic)
    handle_cast({:push, {topic, msg}}, conn)
    EventStream.mark_as_completed({__MODULE__, :docker, id})
    {:noreply, conn}
  end

  def handle_cast({:event, topic, id}, conn) do
    EventStream.mark_as_completed({__MODULE__, topic, id})
    {:noreply, conn}
  end

  @doc false
  def process({topic, id}),
    do: GenServer.cast(__MODULE__, {:event, topic, id})

  @doc """
  Send notification
  """
  @spec push({binary, term}) :: :ok
  def push({topic, _} = notification) when is_binary(topic),
    do: GenServer.cast(__MODULE__, {:push, notification})

  @doc """
  Subscribe to nat topic
  """
  @spec subscribe(binary) :: :ok | {:error, term}
  def subscribe(topic) when is_binary(topic),
    do: GenServer.call(__MODULE__, {:sub, topic})
end
