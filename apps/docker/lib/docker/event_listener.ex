defmodule Docker.EventListener do
  @moduledoc """
  This pid is listening for all docker events from docker daemon and handles them.
  Main events that are handled are: `start`, `stop`, `kill` and `die`
  All this event sare handled as JSON strings and are send into global event bus.
  """
  use GenServer

  alias Docker.Struct.{Container, Event}
  alias Stax.EventStream

  require Logger

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(_) do
    port = start_executable()
    Logger.debug("New docker events spawned with port #{inspect(port)}")

    {:ok, port}
  end

  @doc false
  def terminate(reason, port) do
    Logger.debug("Got termination reason: #{inspect(reason)}. Closing port.")
    Port.info(port)
  end

  @doc false
  def handle_info({:DOWN, _ref, :port, _, reason}, port) do
    Logger.info("Got port failure with reason #{inspect(reason)}")
    {:stop, :failed, port}
  end

  @doc false
  def handle_info({_port, {:data, msg}}, port) do
    Logger.debug("Got docker event: #{inspect(msg)}")

    msg
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.each(&propagate_event/1)

    {:noreply, port}
  end

  def handle_info(_msg, port),
    do: {:noreply, port}

  # Start new docker events executable
  defp start_executable() do
    wrapper =
      :docker
      |> Application.get_env(:wrapper_file)
      |> Path.absname()

    unless File.exists?(wrapper) do
      raise "No wrapper file exists in #{wrapper}"
    end

    unless docker = System.find_executable("docker") do
      raise "No docker executable found in system !"
    end

    port =
      {:spawn_executable, wrapper}
      |> Port.open([:binary, :exit_status, args: [docker] ++ get_args()])

    Port.monitor(port)
    Process.link(port)

    port
  end

  defp get_args() do
    [
      "events",
      "--filter",
      "event=start",
      "--filter",
      "event=die",
      "--filter",
      "event=stop",
      "--filter",
      "event=kill",
      "--filter",
      "type=container",
      "--format",
      "{{json .}}"
    ]
  end

  defp propagate_event(""), do: :ok

  defp propagate_event(msg) do
    case Jason.decode(msg) do
      {:ok, data} ->
        event = %Event{
          id: Map.get(data, "id"),
          event: Map.get(data, "status"),
          container: Map.get(data, "from"),
          name: Kernel.get_in(data, ["Actor", "Attributes", "name"]),
          attributes: Kernel.get_in(data, ["Actor", "Attributes"])
        }

        if event.event == "die" and event.name do
          Container.die(event.name)
        end

        # Logger send docker event to event stream
        EventStream.dispatch({:docker, event})

      {:error, err} ->
        Logger.error("Failed to parse docker event #{inspect(err)}")
    end
  end
end
