defmodule Docker.Struct.Container do
  @moduledoc """
  Default container structure and worker.
  """

  use GenServer, restart: :transient

  alias Docker.PortMapper

  require Logger

  @type t :: %__MODULE__{
          id: binary,
          image: binary,
          name: binary,
          description: binary,
          network: binary,
          ports: [pos_integer | {pos_integer, pos_integer}],
          env: map()
        }

  defstruct id: "",
            image: "",
            name: "",
            description: "",
            network: "",
            ports: [],
            env: %{}

  @doc """
  Start new docker container PID with all it's details
  """
  @spec start_link(t()) :: {:ok, pid}
  def start_link(%__MODULE__{id: ""}),
    do: {:error, "No docker container ID passed"}

  def start_link(%__MODULE__{id: id} = container) when is_binary(id),
    do: GenServer.start_link(__MODULE__, container, name: via_tuple(id))

  @doc false
  def init(%__MODULE__{} = container),
    do: {:ok, container}

  @doc false
  def terminate(reason, %__MODULE__{id: id} = state) do
    Logger.debug(fn ->
      "Docker container #{id} terminating with reason: #{inspect(reason)}.\n #{inspect(state)}"
    end)

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

  @doc """
  Terminate container process by container ID
  """
  @spec terminate(binary) :: :ok
  def terminate(id) when is_binary(id) do
    id
    |> via_tuple()
    |> GenServer.cast(:terminate)
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
    ports: [{64396, 3000}]
  }
  ```
  """
  @spec reserve_ports(t()) :: t()
  def reserve_ports(%__MODULE__{ports: ports} = container) do
    reserved = Enum.map(ports, &do_reserve_ports/1)
    %__MODULE__{container | ports: reserved}
  end

  # Reserve ports
  defp do_reserve_ports(port) when is_integer(port),
    do: {Docker.PortMapper.random(), port}

  defp do_reserve_ports(port), do: port

  # Unlocks reserved port
  defp free_port({reserved_port, _port}),
    do: PortMapper.terminate(reserved_port)

  defp free_port(_), do: :ok

  # Generating name for registry
  defp via_tuple(id) when is_binary(id),
    do: {:via, Registry, {Docker.ContainerRegistry, id}}
end
