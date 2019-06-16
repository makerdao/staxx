defmodule Stacks.DockerEventHandler do
  @moduledoc """
  Process that handles container failures from handleing and parsing docker events.
  All docker events are streaaming into NATS.
  This process connects to NATS.io and read all failure events from it.
  On failure event catch it will propagate this event to required Stack
  notifing it that container from stack has failed.

  After catching this event by stack process it will make a decision on what to do.
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

  @doc """
  Subscribe process for docker container event handling
  It means if some process will subscribe for events for given container id
  this process will receive notification when container will be terminated.

  This is very usefull for stack-plugins that will handle it's child terminations

  Notification will be received in format:
  ```elixir
  {:container_die, "some_cintainer_id"}
  ```
  """
  @spec subscribe(binary) :: {:ok, pid} | {:error, term}
  def subscribe(container_id) when is_binary(container_id) do
    case Registry.register(Stacks.DockerEvents, container_id, nil) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_registered, pid}} ->
        {:ok, pid}

      err ->
        err
    end
  end

  def subscribe(container_id),
    do: {:error, "Wrong container ID passed"}

  #
  # Private functions
  #

  # Send internal notifications about container failure
  defp handle_docker_event(%{event: "die", id: container_id} = event) do
    Logger.debug("Container #{container_id} died: #{inspect(event, pretty: true)}")

    Registry.dispatch(Stacks.DockerEvents, container_id, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:container_die, container_id})
    end)
  end

  defp handle_docker_event(_), do: :ok
end
