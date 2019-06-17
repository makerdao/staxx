defmodule Stacks.Watcher do
  @moduledoc """
  Stack watcher. Will handle list of resources for stack
  """
  use GenServer, restart: :transient

  require Logger

  @timeout 180_000

  defmodule State do
    @moduledoc false

    @type containers :: %{binary => [{pos_integer, pos_integer}]}

    @type t :: %__MODULE__{
            id: binary,
            stacks: %{binary => containers()}
          }

    @enforce_keys [:id]
    defstruct id: nil, stacks: %{}
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
  def handle_call(:info, _from, %State{id: id, stacks: stacks} = state) do
    Logger.debug("Stack #{id}: Loading list of running containers")

    urls =
      stacks
      |> Enum.map(fn {stack_name, containers} ->
        {stack_name, list_of_exported_urls(containers)}
      end)
      |> Enum.into(%{})

    {:reply, urls, state}
  end

  @doc false
  def handle_cast(
        {:container_failed, _container_id},
        %State{id: _id, stacks: _list} = state
      ) do
    # case Map.has_key?(list, container_id) do
    # false ->
    # {:noreply, state}

    # true ->
    # Logger.debug("Stack #{id}: Container died #{container_id}")
    # {:noreply, state}
    # end
    Logger.debug("Container failure should be reworked")
    {:noreply, state}
  end

  @doc false
  def handle_cast(:stop, %State{id: id, stacks: list} = state) do
    Logger.debug("Stack #{id}: Stopping watcher process and containers: #{inspect(list)}")

    list
    |> Enum.map(fn {_stack_name, containers} -> containers end)
    |> Enum.map(&stop_containers/1)

    {:stop, :normal, state}
  end

  @doc false
  def handle_cast(
        {:add, stack_name, container_id, ports},
        %State{id: id, stacks: list} = state
      ) do
    Logger.debug(
      "Stack #{id}: Added new container to stack #{stack_name}: #{container_id}\n with list of ports: #{
        inspect(ports)
      }"
    )

    containers = Map.get(list, stack_name, %{})

    updated =
      case Map.has_key?(containers, container_id) do
        true ->
          list

        false ->
          Map.put(containers, container_id, ports)
      end

    {:noreply, %State{state | stacks: Map.put(list, stack_name, updated)}}
  end

  @doc """
  Add new container ID to stack watcher
  """
  @spec add_container(binary, binary, binary, [pos_integer]) :: :ok
  def add_container(id, stack_name, container_id, ports \\ []),
    do: GenServer.cast(get_pid(id), {:add, stack_name, container_id, ports})

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

  # Stop list of containers
  defp stop_containers(list) do
    list
    |> Map.keys()
    |> Enum.map(&Task.async(Docker, :stop, [&1]))
    |> Enum.map(&Task.await(&1, @timeout))
  end

  # Get only external ports from list of containers
  defp pick_ports({port, _}), do: port
  defp pick_ports(_), do: nil

  defp list_of_exported_urls(containers) do
    front_url = Application.get_env(:stacks, :front_url, "http://localhost")

    containers
    |> Enum.map(fn {_id, ports} -> ports end)
    |> List.flatten()
    |> Enum.map(&pick_ports/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&"#{front_url}:#{&1}")
  end
end
