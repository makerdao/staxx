defmodule Docker.Events do
  @moduledoc """
  Module that handles
  """
  use GenServer

  alias Docker.Struct.{Container, Event}

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

    case Jason.decode(msg) do
      {:ok, data} ->
        event = %Event{
          id: Map.get(data, "id"),
          event: Map.get(data, "status"),
          container: Map.get(data, "from"),
          attributes: Kernel.get_in(data, ["Actor", "Attributes"])
        }

        if event.event == "die" do
          Container.terminate(event.id)
        end

        :docker
        |> Application.get_env(:nats_docker_events_topic, "Docker.Events")
        |> EventBus.push(event)

      {:error, err} ->
        Logger.error("Failed to parse docker event #{inspect(err)}")
    end

    {:noreply, port}
  end

  def handle_info(_msg, port) do
    # IO.inspect(msg)
    {:noreply, port}
  end

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
      "event=create",
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
end
