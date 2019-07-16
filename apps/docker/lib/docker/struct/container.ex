defmodule Docker.Struct.Container do
  @moduledoc """
  Default container structure and worker.
  """

  use GenServer, restart: :temporary

  alias Docker.PortMapper

  require Logger

  @type t :: %__MODULE__{
          permanent: boolean,
          id: binary,
          image: binary,
          name: binary,
          description: binary,
          network: binary,
          cmd: binary,
          ports: [pos_integer | {pos_integer, pos_integer}],
          env: map()
        }

  defstruct permanent: true,
            id: "",
            image: "",
            name: "",
            description: "",
            network: "",
            cmd: "",
            ports: [],
            env: %{}

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
  def init(%__MODULE__{id: ""} = container) do
    # Enabling trap exit for process
    Process.flag(:trap_exit, true)
    # In case of missing container ID
    # it will try to start new container using `Docker.start_rm/1`
    {:ok, container, {:continue, :start_container}}
  end

  @doc false
  def init(%__MODULE__{id: id} = container) when is_binary(id) do
    # Enabling trap exit for process
    Process.flag(:trap_exit, true)
    {:ok, container}
  end

  def handle_continue(:start_container, %__MODULE__{} = container) do
    case Docker.start_rm(container) do
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

  # Because of we will spawn new port process in `handle_continue/2`
  # We have to handle it's termination.
  # Otherwise system will terminate GenServer and it will send container stop signal
  def handle_info({:EXIT, from, :normal}, state) when is_port(from),
    do: {:noreply, state}

  @doc false
  def handle_info({:EXIT, _from, reason}, state) do
    Logger.debug(fn ->
      """
      Exit trapped for Docker container
        Exit reason: #{inspect(reason)}
        Container details:
          #{inspect(state, pretty: true)}
      """
    end)

    {:stop, reason, state}
  end

  @doc false
  def terminate(reason, %__MODULE__{id: id} = state) do
    Logger.debug(fn ->
      """
      Docker container #{id} terminating:
        Reason: #{inspect(reason)}.
        State:
        #{inspect(state, pretty: true)}
      """
    end)

    if id do
      # Stop container in docker daemon
      res = Docker.stop(id)

      Logger.debug(fn -> "Got response from stop container try: #{inspect(res, pretty: true)}" end)
    end

    # Unreserve ports
    state
    |> Map.get(:ports, [])
    |> Enum.each(&free_port/1)

    :ok
  end

  @doc false
  def handle_cast(:terminate, %__MODULE__{id: id} = state) do
    Logger.debug(fn -> "Terminating container #{id} PID.\n #{inspect(state)}" end)
    {:stop, :normal, state}
  end

  @doc false
  def handle_cast(:die, %__MODULE__{id: id} = state) do
    Logger.debug(fn -> "Container died #{id} PID.\n #{inspect(state)}" end)
    {:stop, {:shutdown, :died}, state}
  end

  def handle_call(:info, _from, state),
    do: {:reply, state, state}

  @doc """
  Terminate container process by container Name
  """
  @spec terminate(binary) :: :ok
  def terminate(name) when is_binary(name) do
    name
    |> via_tuple()
    |> GenServer.cast(:terminate)
  end

  @doc """
  Send die event from docker to container process by container Name
  """
  @spec die(binary) :: :ok
  def die(name) when is_binary(name) do
    name
    |> via_tuple()
    |> GenServer.cast(:die)
  end

  @doc """
  Does port reservation.
  It picks random ports from `Docker.PortMapper` and assign ports from container to
  this random ports.

  Example:
  ```elixir
  iex(1)> %Docker.Struct.Container{ports: [3000]} |> Docker.Struct.Container.reserve_ports()
  %Docker.Struct.Container{
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

  # Reserve ports
  defp do_reserve_ports(port) when is_integer(port),
    do: {Docker.PortMapper.random(), port}

  defp do_reserve_ports(port), do: port

  # Unlocks reserved port
  defp free_port({reserved_port, port}) do
    PortMapper.terminate(reserved_port)
    port
  end

  defp free_port(port), do: port

  # Generating name for registry
  defp via_tuple(id) when is_binary(id),
    do: {:via, Registry, {Docker.ContainerRegistry, id}}

  defp rebuild_ports(ports) do
    ports
    |> Enum.map(&refine_port/1)
  end

  defp refine_port({binded, port}),
    do: %{binded => port}

  defp refine_port(port),
    do: port
end

defimpl Poison.Encoder, for: Docker.Struct.Container do
  def encode(container, opts) do
    container
    |> Docker.Struct.Container.to_json()
    |> Poison.Encoder.Map.encode(opts)
  end
end

defimpl Jason.Encoder, for: Docker.Struct.Container do
  def encode(container, opts) do
    container
    |> Docker.Struct.Container.to_json()
    |> Jason.Encode.map(opts)
  end
end
