defmodule Staxx.DeploymentScope.Scope.StackManager do
  @moduledoc """
  This process is an owner of list of stack containers.
  It starts with stack name and will supervise list of containers.
  """
  use GenServer, restart: :temporary

  require Logger

  alias Staxx.Testchain
  alias Staxx.Docker
  alias Staxx.Docker.Container
  alias Staxx.EventStream.Notification
  alias Staxx.DeploymentScope.StackRegistry
  alias Staxx.DeploymentScope.Stack.{ConfigLoader, Config}

  @typedoc """
  Stack status
  """
  @type status :: :initializing | :ready | :failed | :terminate

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            scope_id: binary,
            name: binary,
            status: Staxx.DeploymentScope.Scope.StackManager.status(),
            children: [pid]
          }
    defstruct scope_id: "", name: "", status: :initializing, children: []
  end

  def child_spec(scope_id, stack_name) do
    %{
      id: "#{scope_id}:#{stack_name}",
      start: {__MODULE__, :start_link, [{scope_id, stack_name}]},
      restart: :temporary
    }
  end

  @doc """
  Start new stack supervisor for application
  """
  @spec start_link({binary, binary}) :: GenServer.on_start()
  def start_link({scope_id, stack_name}),
    do:
      GenServer.start_link(__MODULE__, {scope_id, stack_name},
        name: via_tuple(scope_id, stack_name)
      )

  # TODO: start manager container
  # get stack config
  # create new worker with manager
  # add functions for starting additional containers
  #
  @impl true
  def init({scope_id, stack_name}) do
    Logger.debug(fn -> "Starting new manager for stack with name: #{stack_name}" end)

    Process.flag(:trap_exit, true)

    res =
      stack_name
      |> ConfigLoader.get()
      |> do_init(scope_id, stack_name)

    case res do
      {:ok, state} ->
        notify_status(state, :initializing)
        {:ok, state}

      err ->
        err
    end
  end

  @impl true
  def handle_cast(:stop, %State{scope_id: id, name: name} = state) do
    Logger.debug(fn -> "#{id}: Terminating Stack #{name}" end)
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:set_status, status}, %State{scope_id: id, name: name} = state) do
    Logger.debug(fn -> "#{id}: Stack #{name} changed status to #{status}" end)
    # Send notification about stack status event
    notify_status(state, status)

    {:noreply, %State{state | status: status}}
  end

  @impl true
  def handle_call(
        {:start_container, container},
        _from,
        %State{scope_id: id, name: name, children: children} = state
      ) do
    case do_start_container(container, name) do
      {:ok, pid} ->
        Logger.debug(fn ->
          """
          #{id}: Starting new container for stack #{name}:
          #{inspect(container, pretty: true)}
          """
        end)

        {:reply, {:ok, pid}, %State{state | children: children ++ [pid]}}

      {:error, err} ->
        Logger.error(fn ->
          "#{id}: Error starting container for stack #{name}: #{inspect(err)}"
        end)

        {:reply, {:error, err}, state}
    end
  end

  @impl true
  def handle_call(:info, _from, %State{name: name, status: status, children: children} = state) do
    res =
      children
      |> Enum.map(&Task.async(GenServer, :call, [&1, :info]))
      |> Enum.map(&Task.await/1)

    {:reply, %{stack_name: name, status: status, containers: res}, state}
  end

  @impl true
  def handle_info({:EXIT, from, :normal}, %State{children: children} = state),
    do: {:noreply, %State{state | children: List.delete(children, from)}}

  @impl true
  def handle_info({:EXIT, from, reason}, state) do
    # No need to remove container pid from children list.
    # Manager service will terminate
    Logger.debug(fn ->
      "Some containers failed with non :normal reason #{inspect(from)} - #{inspect(reason)}"
    end)

    {:stop, :shutdown, state}
  end

  @impl true
  def terminate(_reason, %State{scope_id: id, name: name} = state) do
    Logger.debug(fn -> "#{id}: Terminating stack #{name} and it's manager process" end)
    notify_status(state, :terminate)
    :ok
  end

  @doc """
  Start new container for running stack
  """
  @spec start_container(binary, binary, Container.t()) :: {:ok, pid} | {:error, term}
  def start_container(scope_id, stack_name, %Container{} = container) do
    merged_env =
      container
      |> Map.get(:env, %{})
      |> Map.merge(default_env(scope_id, stack_name))

    scope_id
    |> via_tuple(stack_name)
    |> GenServer.call({:start_container, %Container{container | env: merged_env}})
  end

  @doc """
  Check is stack is running for given scope id & stack name
  """
  @spec alive?(binary, binary) :: boolean
  def alive?(scope_id, stack_name) do
    scope_id
    |> via_tuple(stack_name)
    |> GenServer.whereis()
    |> case do
      nil ->
        false

      pid ->
        Process.alive?(pid)
    end
  end

  @doc """
  Set new status
  """
  @spec set_status(binary, binary, status()) :: :ok | {:error, term}
  def set_status(scope_id, stack_name, status) when is_atom(status) do
    scope_id
    |> via_tuple(stack_name)
    |> GenServer.cast({:set_status, status})
  end

  @doc """
  Get information about stack by pid
  """
  @spec info(pid) :: list
  def info(pid) when is_pid(pid),
    do: GenServer.call(pid, :info)

  @doc """
  Get information about stack by id/name pair
  """
  @spec info(binary, binary) :: list
  def info(scope_id, stack_name) do
    scope_id
    |> via_tuple(stack_name)
    |> GenServer.call(:info)
  end

  @doc """
  Send stop comnmand to Stack Manager service
  """
  @spec stop(binary, binary) :: :ok
  def stop(scope_id, stack_name) do
    scope_id
    |> via_tuple(stack_name)
    |> GenServer.cast(:stop)
  end

  @doc """
  Generate naming via tuple for stack supervisor
  """
  @spec via_tuple(binary, binary) :: {:via, Registry, {StackRegistry, binary}}
  def via_tuple(scope_id, stack_name),
    do: {:via, Registry, {StackRegistry, "#{scope_id}:#{stack_name}"}}

  #
  # Private functions
  #
  defp do_init(%Config{manager: nil}, scope_id, stack_name) do
    Logger.debug(fn -> "#{scope_id}: No manager container for stack #{stack_name}" end)

    {:ok, %State{scope_id: scope_id, name: stack_name, children: []}}
  end

  defp do_init(%Config{manager: image}, scope_id, stack_name) do
    with container <- manager_config(scope_id, stack_name, image),
         {:ok, pid} <- do_start_container(container, stack_name) do
      Logger.debug(fn ->
        "#{scope_id}: Loaded manager #{image} for stack #{stack_name} #{inspect(pid)}"
      end)

      {:ok, %State{scope_id: scope_id, name: stack_name, children: [pid]}}
    else
      err ->
        Logger.debug(fn ->
          "#{scope_id}: Something went wrong on starting manager: #{inspect(err)}"
        end)

        {:error, :failed_to_start}
    end
  end

  defp do_start_container(%Container{image: image} = container, stack_name) do
    with true <- ConfigLoader.has_image?(stack_name, image),
         {:ok, pid} <- Container.start_link(container) do
      {:ok, pid}
    else
      false ->
        {:error, :not_allowed}

      {:error, err} ->
        {:error, err}
    end
  end

  # Generate new `%Container{}` for manager service
  defp manager_config(scope_id, stack_name, image) do
    %Container{
      image: image,
      name: "",
      network: Docker.get_nats_network(),
      ports: [],
      env: default_env(scope_id, stack_name)
    }
  end

  defp default_env(scope_id, stack_name) do
    %{
      "STACK_ID" => scope_id,
      "STACK_NAME" => stack_name,
      "WEB_API_URL" => "http://#{Testchain.host()}:4000",
      "NATS_URL" => Testchain.nats_url()
    }
  end

  defp notify_status(%State{scope_id: id, name: name}, status),
    do:
      Notification.notify(id, "stack:status", %{
        scope_id: id,
        stack_name: name,
        status: status
      })
end
