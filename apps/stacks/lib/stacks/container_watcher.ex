defmodule Stacks.ContainerWatcher do
  @moduledoc """
  Process that handles container failures for running stacks
  """
  use GenServer

  require Logger

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(state) do
    EventBus.Nats.subscribe(Application.get_env(:stacks, :docker_events_topic))
    {:ok, state}
  end

  @doc false
  def handle_info({:msg, %{body: body}}, state) do
    case Jason.decode(body, keys: :atoms) do
      {:ok, data} ->
        handle_docker_event(data)

      {:error, err} ->
        Logger.error("Failed to decode docker event with error: #{inspect(err)}")
    end

    {:noreply, state}
  end

  #
  # Private functions
  #
  defp handle_docker_event(%{event: "die", id: container_id} = event) do
    Logger.debug("Container #{container_id} died: #{inspect(event)}")

    case Stacks.container_failed(container_id) do
      :ok ->
        :ok

      {:error, err} ->
        Logger.error("Failed to notify container failure #{inspect(err)}")
        :ok
    end
  end

  defp handle_docker_event(_), do: :ok
end
