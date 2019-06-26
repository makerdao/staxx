defmodule DeploymentScope.Scope.StackManager do
  @moduledoc """
  This process is an owner of list of stack containers.
  It starts with stack name and will supervise list of containers.
  """
  use GenServer, restart: :temporary

  require Logger

  alias Docker.Struct.Container
  alias Stacks.ConfigLoader
  alias Stacks.Stack.Config

  @typedoc """
  Stack status
  """
  @type status :: :initializing | :ready | :failed

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            scope_id: binary,
            name: binary,
            status: DeploymentScope.Scope.StackManager.status()
          }
    defstruct scope_id: "", name: "", status: :initializing
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

    with %Config{manager: image} <- ConfigLoader.get(stack_name),
         container <- manager_config(scope_id, stack_name, image),
         {:ok, pid} <- do_start_container(container, stack_name) do
      Logger.debug(fn ->
        "#{scope_id}: Loaded manager #{image} for stack #{stack_name} #{inspect(pid)}"
      end)

      {:ok, %State{scope_id: scope_id, name: stack_name}}
    else
      err ->
        Logger.debug(fn ->
          "#{scope_id}: Something went wrong on starting manager: #{inspect(err)}"
        end)

        {:error, :failed_to_start}
    end
  end

  @impl true
  def handle_cast({:set_status, status}, %State{scope_id: id, name: name} = state) do
    Logger.debug(fn -> "#{id}: Stack #{name} changed status to #{status}" end)
    # TODO: Send notification to Event bus
    {:noreply, %State{state | status: status}}
  end

  @impl true
  def handle_call({:start_container, container}, _from, %State{scope_id: id, name: name} = state) do
    case do_start_container(container, name) do
      {:ok, pid} ->
        Logger.debug(fn ->
          """
          #{id}: Starting new container for stack #{name}:
          #{inspect(container, pretty: true)}
          """
        end)

        {:reply, {:ok, pid}, state}

      {:error, err} ->
        Logger.error(fn ->
          "#{id}: Error starting container for stack #{name}: #{inspect(err)}"
        end)

        {:reply, {:error, err}, state}
    end
  end

  @impl true
  def handle_info({:EXIT, _from, :normal}, state),
    do: {:noreply, state}

  @impl true
  def handle_info({:EXIT, from, reason}, state) do
    Logger.debug(fn ->
      "Some containers failed with non :normal reason #{inspect(from)} - #{inspect(reason)}"
    end)

    {:stop, :shutdown, state}
  end

  @impl true
  def terminate(_reason, %State{scope_id: id, name: name}) do
    Logger.debug(fn -> "#{id}: Terminating stack #{name} and it's manager process" end)
    # TODO: send notification about terminating stack
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
    |> Process.alive?()
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
  Generate naming via tuple for stack supervisor
  """
  @spec via_tuple(binary, binary) :: {:via, Registry, {DeploymentScope.StackRegistry, binary}}
  def via_tuple(scope_id, stack_name),
    do: {:via, Registry, {DeploymentScope.StackRegistry, "#{scope_id}:#{stack_name}"}}

  #
  # Private functions
  #

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
      network: scope_id,
      ports: [],
      env: default_env(scope_id, stack_name)
    }
  end

  defp default_env(scope_id, stack_name) do
    %{
      "STACK_ID" => scope_id,
      "STACK_NAME" => stack_name,
      "WEB_API_URL" => "http://host.docker.internal:4000",
      "NATS_URL" => "http://host.docker.internal:4222"
    }
  end
end
