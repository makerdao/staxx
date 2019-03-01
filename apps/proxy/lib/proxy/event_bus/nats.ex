defmodule Proxy.EventBus.Nats do
  @moduledoc """
  Nats handler. 
  """
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    nats_config = Application.get_env(:proxy, :nats)
    {:ok, conn} = Gnat.start_link(nats_config)
    Logger.debug("Connected to Nats.io with config #{inspect(nats_config)}")

    {:ok, conn}
  end

  def handle_cast({:push, {topic, event}}, conn) when is_binary(topic) do
    Gnat.pub(conn, topic, Jason.encode!(event), [])
    {:noreply, conn}
  end

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
end
