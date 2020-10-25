defmodule Staxx.Instance.Stack do
  @moduledoc """
  Manages stack lifecircle.

  This process is an owner of all stack containers per instance.
  """
  use GenServer, restart: :temporary

  require Logger

  alias Staxx.Testchain
  alias Staxx.Instance
  alias Staxx.Docker
  alias Staxx.Docker.Container
  alias Staxx.EventStream.Notification
  alias Staxx.Instance.Stack
  alias Staxx.Instance.StackRegistry
  alias Staxx.Instance.Stack.{ConfigLoader, Config}

  @typedoc """
  Stack status
  """
  @type status :: :initializing | :ready | :failed | :terminate

  @typedoc """
  Stack information format.
  """
  @type info :: {binary, %{status: status(), stack_name: binary, containers: [Container.t()]}} | nil

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            instance_id: Instance.id(),
            name: binary,
            status: Stack.status(),
            container_pids: [pid]
          }
    defstruct instance_id: "", name: "", status: :initializing, container_pids: []
  end

  @doc false
  def child_spec(instance_id, name) do
    %{
      id: "#{instance_id}:#{name}",
      start: {__MODULE__, :start_link, [{instance_id, name}]},
      restart: :temporary
    }
  end

  @doc """
  Start new stack supervisor for application
  """
  @spec start_link({Instance.id(), binary}) :: GenServer.on_start()
  def start_link({instance_id, name}),
    do:
      GenServer.start_link(__MODULE__, {instance_id, name},
        name: via_tuple(instance_id, name)
      )

  # TODO: start manager container
  # get stack config
  # create new worker with manager
  # add functions for starting additional containers
  #
  @impl true
  def init({instance_id, name}) do
    Logger.debug(fn ->
      """
      Instance ID: #{instance_id}
      Starting new stack: #{name}
      """
    end)

    Process.flag(:trap_exit, true)

    res =
      name
      |> ConfigLoader.get()
      |> do_init(instance_id, name)

    case res do
      {:ok, state} ->
        notify_status(state, :initializing)
        {:ok, state}

      err ->
        err
    end
  end

  @impl true
  def handle_cast(:stop, %State{instance_id: id, name: name} = state) do
    Logger.debug(fn -> "Instance #{id}: Terminating Stack #{name}" end)
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:set_status, status}, %State{instance_id: id, name: name} = state) do
    Logger.debug(fn -> "Instance #{id}: Stack #{name} changed status to #{status}" end)
    # Send notification about stack status event
    notify_status(state, status)

    {:noreply, %State{state | status: status}}
  end

  @impl true
  def handle_call(
        {:start_container, container},
        _from,
        %State{instance_id: id, name: name, container_pids: container_pids} = state
      ) do
    case do_start_container(container, name) do
      {:ok, pid} ->
        Logger.debug(fn ->
          """
          Instance #{id}: Starting new container for stack #{name}:
          #{inspect(container, pretty: true)}
          """
        end)

        {:reply, {:ok, pid}, %State{state | container_pids: container_pids ++ [pid]}}

      {:error, err} ->
        Logger.error(fn ->
          "Instance #{id}: Error starting container for stack #{name}: #{inspect(err)}"
        end)

        {:reply, {:error, err}, state}
    end
  end

  @impl true
  def handle_call(
        :info,
        _from,
        %State{name: name, status: status, container_pids: container_pids} = state
      ) do
    res =
      container_pids
      |> Enum.map(&Task.async(GenServer, :call, [&1, :info]))
      |> Enum.map(&Task.await/1)

    {:reply, {name, %{status: status, stack_name: name, containers: res}}, state}
  end

  @impl true
  def handle_info({:EXIT, from, :normal}, %State{container_pids: container_pids} = state),
    do: {:noreply, %State{state | container_pids: List.delete(container_pids, from)}}

  @impl true
  def handle_info({:EXIT, from, reason}, state) do
    # No need to remove container pid from `container_pids` list.
    # Manager service will terminate
    Logger.debug(fn ->
      "Some containers failed with non :normal reason #{inspect(from)} - #{inspect(reason)}"
    end)

    {:stop, :shutdown, state}
  end

  @impl true
  def terminate(_reason, %State{instance_id: id, name: name} = state) do
    Logger.debug(fn ->
      "Instance #{id}: Terminating stack #{name} and it's manager process"
    end)

    notify_status(state, :terminate)
    :ok
  end

  @doc """
  Start new container for running stack
  """
  @spec start_container(Instance.id(), binary, Container.t()) :: {:ok, pid} | {:error, term}
  def start_container(instance_id, name, %Container{} = container) do
    merged_env =
      container
      |> Map.get(:env, %{})
      |> Map.merge(default_env(instance_id, name))

    instance_id
    |> via_tuple(name)
    |> GenServer.call({:start_container, %Container{container | env: merged_env}})
  end

  @doc """
  Check is stack is running for given scope id & stack name
  """
  @spec alive?(Instance.id(), binary) :: boolean
  def alive?(instance_id, name) do
    instance_id
    |> via_tuple(name)
    |> GenServer.whereis()
    |> case do
      nil ->
        false

      pid ->
        Process.alive?(pid)
    end
  end

  @doc """
  Set new instance status.
  """
  @spec set_status(Instance.id(), binary, status()) :: :ok | {:error, term}
  def set_status(instance_id, name, status) when is_atom(status) do
    instance_id
    |> via_tuple(name)
    |> GenServer.cast({:set_status, status})
  end

  @doc """
  Get information about stack by `pid`.
  """
  @spec info(pid) :: info()
  def info(pid) when is_pid(pid),
    do: GenServer.call(pid, :info)

  @doc """
  Get information about stack by id/name pair.
  """
  @spec info(Instance.id(), binary) :: list
  def info(instance_id, name) do
    instance_id
    |> via_tuple(name)
    |> GenServer.call(:info)
  end

  @doc """
  Send stop command to stack service.
  """
  @spec stop(Instance.id(), binary) :: :ok
  def stop(instance_id, name) do
    instance_id
    |> via_tuple(name)
    |> GenServer.cast(:stop)
  end

  @doc """
  Generate naming via tuple for stack supervisor
  """
  @spec via_tuple(Instance.id(), binary) :: {:via, Registry, {StackRegistry, binary}}
  def via_tuple(instance_id, name),
    do: {:via, Registry, {StackRegistry, "#{instance_id}:#{name}"}}

  #
  # Private functions
  #
  defp do_init(%Config{manager: nil}, instance_id, name) do
    Logger.debug(fn ->
      "Instance #{instance_id}: No manager container for stack #{name}"
    end)

    {:ok, %State{instance_id: instance_id, name: name, container_pids: []}}
  end

  defp do_init(%Config{manager: image}, instance_id, name) do
    with container <- manager_config(instance_id, name, image),
         {:ok, pid} <- do_start_container(container, name) do
      Logger.debug(fn ->
        "Instance #{instance_id}: Loaded manager #{image} for stack #{name} #{inspect(pid)}"
      end)

      {:ok, %State{instance_id: instance_id, name: name, container_pids: [pid]}}
    else
      err ->
        Logger.debug(fn ->
          "Instance #{instance_id}: Something went wrong on starting manager: #{
            inspect(err)
          }"
        end)

        {:error, :failed_to_start}
    end
  end

  defp do_start_container(%Container{image: image} = container, name) do
    with true <- ConfigLoader.has_image?(name, image),
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
  defp manager_config(instance_id, name, image) do
    %Container{
      image: image,
      name: "",
      network: Docker.get_nats_network(),
      ports: [],
      env: default_env(instance_id, name)
    }
  end

  defp default_env(instance_id, name) do
    %{
      "INSTANCE_ID" => instance_id,
      "STACK_NAME" => name,
      "WEB_API_URL" => "http://#{Testchain.host()}:4000",
      "NATS_URL" => Testchain.nats_url()
    }
  end

  defp notify_status(%State{instance_id: id, name: name}, status),
    do:
      Notification.notify(id, "stack:status", %{
        instance_id: id,
        stack_name: name,
        status: status
      })
end
