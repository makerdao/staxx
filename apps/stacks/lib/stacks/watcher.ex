defmodule Stacks.Watcher do
  @moduledoc """
  Stack watcher. Will handle list of resources for stack
  """

  use GenServer, restart: :transient

  require Logger

  @timeout 180_000

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            id: binary,
            containers: [binary]
          }

    @enforce_keys [:id]
    defstruct id: nil, containers: []
  end

  @doc false
  def start_link(id) do
    Logger.debug("Starting watcher for #{id}")

    GenServer.start_link(__MODULE__, %State{id: id}, name: {:via, Registry, {Stacks.Registry, id}})
  end

  @doc false
  def init(state), do: {:ok, state}

  @doc false
  def handle_cast(:stop, %State{id: id, containers: list} = state) do
    Logger.debug("Stack #{id}: Stopping watcher process and containers: #{inspect(list)}")

    list
    |> Enum.map(&Task.async(Proxy.Chain.Docker, :stop, [&1]))
    |> Enum.map(&Task.await(&1, @timeout))

    {:stop, :normal, state}
  end

  @doc false
  def handle_cast({:add, container_id}, %State{id: id, containers: list} = state) do
    Logger.debug("Stack #{id}: Added new container to list #{container_id}")

    updated =
      case Enum.member?(list, container_id) do
        true ->
          list

        false ->
          list ++ [container_id]
      end

    {:noreply, %State{state | containers: updated}}
  end

  @doc """
  Add new container ID to stack watcher
  """
  @spec add_container(binary, binary) :: :ok
  def add_container(id, container_id),
    do: GenServer.cast(get_pid(id), {:add, container_id})

  @doc """
  Send stop command to watcher supervisor
  """
  @spec stop(binary) :: :ok
  def stop(id),
    do: GenServer.cast(get_pid(id), :stop)

  @doc """
  Check if watcher for stack with given id is alive
  """
  @spec alive?(binary) :: boolean
  def alive?(id),
    do: get_pid(id) != nil

  @doc """
  Get GenServer pid by id
  """
  @spec get_pid(binary) :: nil | pid()
  def get_pid(id) do
    case Registry.lookup(Stacks.Registry, id) do
      [{pid, _}] ->
        pid

      _ ->
        nil
    end
  end
end
