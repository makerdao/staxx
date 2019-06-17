defmodule Docker.Struct.Container do
  @moduledoc """
  Default container structure
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
    do: GenServer.start_link(__MODULE__, container, name: String.to_atom(id))

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
  Terminate container PID by container ID
  """
  @spec terminate(binary) :: :ok
  def terminate(id) when is_binary(id) do
    id
    |> String.to_atom()
    |> GenServer.cast(:terminate)
  end

  # Unlocks reserved port
  defp free_port({reserved_port, _port}),
    do: PortMapper.terminate(reserved_port)

  defp free_port(_), do: :ok
end
