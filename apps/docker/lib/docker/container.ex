defmodule Staxx.Docker.Container do
  @moduledoc """
  Default container structure and worker.
  """

  use GenServer, restart: :temporary

  alias Staxx.Docker
  alias Staxx.Docker.PortMapper
  alias Staxx.Docker.ContainerRegistry

  require Logger

  @type t :: %__MODULE__{
          permanent: boolean,
          existing: boolean,
          id: binary,
          image: binary,
          name: binary,
          description: binary,
          network: binary,
          cmd: binary,
          ports: [pos_integer | {pos_integer, pos_integer}],
          env: map(),
          dev_mode: boolean(),
          rm: boolean(),
          volumes: [binary],
          assign_user: boolean()
        }

  defstruct permanent: true,
            existing: false,
            id: "",
            image: "",
            name: "",
            description: "",
            network: "",
            cmd: "",
            ports: [],
            env: %{},
            dev_mode: false,
            rm: true,
            volumes: [],
            assign_user: true

  @doc false
  def child_spec(%__MODULE__{name: name} = container) do
    %{
      id: name,
      start: {__MODULE__, :start_link, [container]},
      restart: :temporary,
      type: :worker
    }
  end

  @doc """
  Start new docker container PID with all it's details
  """
  @spec start_link(t()) :: {:ok, pid}
  def start_link(%__MODULE__{name: ""} = container),
    do: start_link(%__MODULE__{container | name: Docker.random_name()})

  def start_link(%__MODULE__{name: name} = container) when is_binary(name),
    do: GenServer.start_link(__MODULE__, container, name: via_tuple(name))

  @doc false
  @impl true
  def init(%__MODULE__{} = container) do
    # Collecting telemetry
    :telemetry.execute(
      [:staxx, :docker, :container, :start],
      %{image: Map.get(container, :image)},
      %{
        id: Map.get(container, :id),
        dev_mode: Map.get(container, :dev_mode, false),
        rm: Map.get(container, :rm)
      }
    )

    # In case of missing container ID
    # it will try to start new container using `Staxx.Docker.run/1`
    {:ok, container, {:continue, :start_container}}
  end

  @doc """
  Creates Docker container struct with given parameters and stack id.
  Returns `Staxx.Docker.Container.t() `
  """
  @spec create_container(map, binary()) :: Staxx.Docker.Container.t()
  def create_container(params, stack_id) do
    %__MODULE__{
      image: Map.get(params, "image", ""),
      name: Map.get(params, "name", ""),
      network: Map.get(params, "network", stack_id),
      cmd: Map.get(params, "cmd", ""),
      ports: Map.get(params, "ports", []),
      env: parse_env(Map.get(params, "env", %{})),
      dev_mode: Map.get(params, "dev_mode", false)
    }
  end

  #
  # Starts already existing container.
  # Will call `Staxx.Docker.start/1` function.
  # On docker level it will use `docker start name` command for starting.
  #
  @impl true
  def handle_continue(:start_container, %__MODULE__{existing: true, name: name} = container) do
    case Docker.start(name) do
      :ok ->
        Logger.debug(fn ->
          """
          Started existing container with name: #{name}
          Details:
          #{inspect(container, pretty: true)}
          """
        end)

        {:noreply, container}

      {:error, msg} ->
        Logger.error(fn ->
          "Failed to start existing container with err: #{inspect(msg, pretty: true)}"
        end)

        {:stop, {:shutdown, :failed_to_start}, container}
    end
  end

  #
  # Starts new container using `Staxx.Docker.run/1` function.
  # On low level it will use `docker run ****` command.
  #
  @impl true
  def handle_continue(:start_container, %__MODULE__{existing: false} = container) do
    case Docker.run(container) do
      {:ok, %__MODULE__{id: id} = started_container} ->
        Logger.debug(fn ->
          """
          Started new container with id: #{id}
          Details:
          #{inspect(started_container, pretty: true)}
          """
        end)

        {:noreply, started_container}

      {:error, msg} ->
        Logger.error(fn ->
          "Failed to start new container with err: #{inspect(msg, pretty: true)}"
        end)

        {:stop, {:shutdown, :failed_to_start}, container}
    end
  end

  @doc false
  @impl true
  def terminate(reason, %__MODULE__{id: id} = state) do
    Logger.debug(fn ->
      """
      Docker container #{id} terminating:
        Reason: #{inspect(reason)}.
        State:
        #{inspect(state, pretty: true)}
      """
    end)

    # Collecting telemetry
    :telemetry.execute(
      [:staxx, :docker, :container, :stop],
      %{image: Map.get(state, :image)},
      %{
        id: Map.get(state, :id),
        dev_mode: Map.get(state, :dev_mode, false),
        rm: Map.get(state, :rm)
      }
    )

    if id do
      # Stop container in docker daemon
      res = Docker.stop(id)

      Logger.debug(fn -> "Got response from stop container try: #{inspect(res, pretty: true)}" end)
    end

    case reason do
      {:shutdown, :temporary} ->
        Logger.debug(fn -> "Container temporary stop. Ports should not be unlocked !" end)
        :ok

      _ ->
        # Unreserve ports
        state
        |> Map.get(:ports, [])
        |> Enum.each(&free_port/1)
    end

    :ok
  end

  @doc false
  @impl true
  def handle_cast({:die, exit_code}, %__MODULE__{id: id} = state) do
    Logger.debug(fn ->
      "Container died #{id} with exit code #{exit_code}.\n #{inspect(state, pretty: true)}"
    end)

    {:stop, {:shutdown, exit_code}, state}
  end

  @doc false
  @impl true
  def handle_call(:info, _from, state),
    do: {:reply, state, state}

  @doc """
  Get container information for given name/pid
  """
  @spec info(GenServer.server() | binary) :: t()
  def info(name) when is_binary(name) do
    name
    |> via_tuple()
    |> GenServer.call(:info)
  end

  def info(pid),
    do: GenServer.call(pid, :info)

  @doc """
  Stops container process by container Name or PID.
  Exit reason does matter only for temporary stop.
  If reason will be `{:shutdown, :temporary}` system wouldn't free container ports
  """
  @spec stop(GenServer.server() | binary, any()) :: :ok
  def stop(server, reason \\ :shutdown)

  def stop(name, reason) when is_binary(name) do
    name
    |> via_tuple()
    |> GenServer.stop(reason)
  end

  def stop(pid, reason),
    do: GenServer.stop(pid, reason)

  @doc """
  Terminates container but allocated `ports` wouldn't be unlocked for usage.

  Usefull for cases like take/revert snapshot where termporary stop is needed
  but you need to start container again using `%Container{existing: true}`
  with already allocated `ports`.
  """
  @spec stop_temporary(GenServer.server() | binary) :: :ok | {:error, term}
  def stop_temporary(server) do
    :ok = stop(server, {:shutdown, :temporary})

    # because EVM handles `{:EXIT, pid, reason}` we have to catch it here
    # otherwise EVM will decide that container failed and something wrong
    # and as result will terminate whole supervision tree for instance
    receive do
      {:EXIT, _pid, {:shutdown, :temporary}} ->
        :ok
    after
      180_000 ->
        {:error, :timeut_stoping_container}
    end
  end

  @doc """
  Send die event from docker to container process by container Name
  """
  @spec die(binary, pos_integer) :: :ok
  def die(name, exit_code) when is_binary(name) do
    name
    |> via_tuple()
    |> GenServer.cast({:die, exit_code})
  end

  @doc """
  Does port reservation.
  It picks random ports from `Staxx.Docker.PortMapper` and assign ports from container to
  this random ports.

  Example:
  ```elixir
  iex(1)> %Staxx.Docker.Container{ports: [3000]} |> Staxx.Docker.Container.reserve_ports()
  %Staxx.Docker.Container{
    description: "",
    env: %{},
    id: "",
    image: "",
    name: "",
    network: "",
    cmd: "",
    ports: [{64396, 3000}]
  }
  ```
  """
  @spec reserve_ports(t()) :: t()
  def reserve_ports(%__MODULE__{ports: ports} = container) do
    reserved = Enum.map(ports, &do_reserve_ports/1)
    %__MODULE__{container | ports: reserved}
  end

  @doc """
  Free up ports reserved by container
  """
  @spec free_ports(t()) :: t()
  def free_ports(%__MODULE__{ports: ports} = container) do
    updated =
      ports
      |> Enum.each(&free_port/1)

    %__MODULE__{container | ports: updated}
  end

  @doc """
  Repacks structure to be able to pass it as normal map that could be easyly encoded.
  """
  @spec to_json(t()) :: map
  def to_json(%__MODULE__{ports: ports} = container) do
    container
    |> Map.from_struct()
    |> Map.put(:ports, rebuild_ports(ports))
  end

  @doc """
  Check if given container is allowed to be run in "Dev Mode".
  See API docs for more details.
  """
  @spec is_dev_mode(t()) :: boolean
  def is_dev_mode(%__MODULE__{dev_mode: true}),
    do: Docker.dev_mode_allowed?()

  def is_dev_mode(_),
    do: false

  # Reserve ports
  defp do_reserve_ports(port) when is_integer(port),
    do: {PortMapper.random(), port}

  defp do_reserve_ports(port), do: port

  # Unlocks reserved port
  defp free_port({reserved_port, port}) do
    PortMapper.terminate(reserved_port)
    port
  end

  defp free_port(port), do: port

  # Generating name for registry
  defp via_tuple(id) when is_binary(id),
    do: {:via, Registry, {ContainerRegistry, id}}

  defp rebuild_ports(ports) do
    ports
    |> Enum.map(&refine_port/1)
  end

  defp refine_port({binded, port}),
    do: %{binded => port}

  defp refine_port(port),
    do: port

  defp parse_env(map) when is_map(map), do: map
  defp parse_env(_some), do: %{}
end

defimpl Poison.Encoder, for: Staxx.Docker.Container do
  def encode(container, opts) do
    container
    |> Staxx.Docker.Container.to_json()
    |> Poison.Encoder.Map.encode(opts)
  end
end

defimpl Jason.Encoder, for: Staxx.Docker.Container do
  def encode(container, opts) do
    container
    |> Staxx.Docker.Container.to_json()
    |> Jason.Encode.map(opts)
  end
end
