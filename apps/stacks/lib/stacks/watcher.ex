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
            containers: %{binary => term}
          }

    @enforce_keys [:id]
    defstruct id: nil, containers: %{}
  end

  @doc false
  def start_link(id) do
    Logger.debug("Starting watcher for #{id}")

    GenServer.start_link(__MODULE__, %State{id: id}, name: {:via, Registry, {Stacks.Registry, id}})
  end

  @doc false
  def init(state), do: {:ok, state}

  @doc false
  def handle_call(:get_id, _from, %State{id: id} = state),
    do: {:reply, id, state}

  @doc false
  def handle_call(:info, _from, %State{id: id, containers: containers} = state) do
    Logger.debug("Stack #{id}: Loading list of running containers")

    urls =
      containers
      |> Enum.map(fn {_id, ports} -> ports end)
      |> Enum.map(&pick_ports/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&"http://localhost:#{&1}")

    {:reply, urls, state}
  end

  @doc false
  def handle_cast(
        {:container_failed, container_id},
        %State{id: id, containers: list} = state
      ) do
    case Map.has_key?(list, container_id) do
      false ->
        {:noreply, state}

      true ->
        Logger.debug("Stack #{id}: Container died #{container_id}")
        {:noreply, state}
    end
  end

  @doc false
  def handle_cast(:stop, %State{id: id, containers: list} = state) do
    Logger.debug("Stack #{id}: Stopping watcher process and containers: #{inspect(list)}")

    list
    |> Map.keys()
    |> Enum.map(&Task.async(Proxy.Docker, :stop, [&1]))
    |> Enum.map(&Task.await(&1, @timeout))

    {:stop, :normal, state}
  end

  @doc false
  def handle_cast({:add, container_id, ports}, %State{id: id, containers: list} = state) do
    Logger.debug(
      "Stack #{id}: Added new container to list #{container_id}\n with list of ports: #{
        inspect(ports)
      }"
    )

    updated =
      case Map.has_key?(list, container_id) do
        true ->
          list

        false ->
          Map.put(list, container_id, ports)
      end

    {:noreply, %State{state | containers: updated}}
  end

  @doc """
  Add new container ID to stack watcher
  """
  @spec add_container(binary, binary, [pos_integer]) :: :ok
  def add_container(id, container_id, ports \\ []),
    do: GenServer.cast(get_pid(id), {:add, container_id, ports})

  @doc """
  Send notification about caontainer failure
  """
  @spec container_failed(pid, binary) :: :ok
  def container_failed(pid, container_id),
    do: GenServer.cast(pid, {:container_failed, container_id})

  @doc """
  Send stop command to watcher supervisor
  """
  @spec stop(binary) :: :ok
  def stop(id),
    do: GenServer.cast(get_pid(id), :stop)

  @doc """
  Get stack information
  """
  @spec info(binary) :: term
  def info(id),
    do: GenServer.call(get_pid(id), :info)

  @doc """
  Get stack id by watcher pid
  """
  @spec get_id(pid | node) :: binary
  def get_id(pid),
    do: GenServer.call(pid, :get_id)

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

  # Get only external ports from list of containers
  defp pick_ports({port, _}), do: port
  defp pick_ports(_), do: nil
end
