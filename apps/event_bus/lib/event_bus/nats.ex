defmodule EventBus.Nats do
  @moduledoc """
  Nats handler.
  """
  use GenServer

  require Logger

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(_) do
    nats_config = Application.get_env(:proxy, :nats)
    {:ok, conn} = Gnat.start_link(nats_config)
    Logger.debug("Connected to Nats.io with config #{inspect(nats_config)}")

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
