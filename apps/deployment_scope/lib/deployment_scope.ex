defmodule Staxx.DeploymentScope do
  @moduledoc """
  DeploymentScope is responsible for  aggregation of chain + stacks in one scope
  It handle and manage starting chain/stacks in correct order and validation
  """

  require Logger

  alias Staxx.Docker
  alias Staxx.Docker.Container
  alias Staxx.Testchain
  alias Staxx.Testchain.Helper
  alias Staxx.DeploymentScope.ScopesSupervisor
  alias Staxx.DeploymentScope.Scope.DeploymentScopeSupervisor
  alias Staxx.DeploymentScope.Scope.StackManager
  alias Staxx.DeploymentScope.Stack.ConfigLoader

  @doc """
  Start new deployment scope using given configuration
  """
  @spec start(map, binary) :: {:ok, binary} | {:error, term}
  def start(params, email \\ "")

  def start(%{"testchain" => %{"config" => %{"id" => id}}} = params, email) do
    stacks = Map.drop(params, ["testchain"])

    Logger.debug(fn ->
      """
      Starting deployment scope with existing chain #{id}
      Config:
      #{inspect(stacks, pretty: true)}
      """
    end)

    start(id, id, stacks, email)
  end

  def start(%{"testchain" => %{"config" => config}} = params, email) do
    chain_config =
      config
      |> Helper.config_from_payload()
      |> Helper.generate_id!()

    stacks = Map.drop(params, ["testchain"])

    Logger.debug(fn ->
      """
      Starting deployment scope with new chain
      Chain configuration:
      #{inspect(chain_config, pretty: true)}

      Stacks Config:
      #{inspect(stacks, pretty: true)}
      """
    end)

    start(chain_config.id, chain_config, stacks, email)
  end

  def start(_, _),
    do: {:error, "wrong chain config"}

  @doc """
  Start supervision tree for new deployment scope
  """
  @spec start(binary, binary | map, map, binary) :: {:ok, Testchain.evm_id()} | {:error, term}
  def start(id, chain_config_or_id, stacks, email \\ "") when is_binary(id) do
    modules = get_stack_names(stacks)
    Logger.debug("Starting new deployment scope with modules: #{inspect(modules)}")

    # Binding email to chain configuration
    chain_config_or_id =
      chain_config_or_id
      |> case do
        config when is_map(config) ->
          Map.put(config, :email, email)

        id ->
          id
      end

    with :ok <- validate_stacks(modules),
         {:ok, pid} <- ScopesSupervisor.start_scope({id, chain_config_or_id, stacks}) do
      Logger.debug("Started chain supervisor tree #{inspect(pid)} for stack #{id}")

      {:ok, id}
    else
      {:error, err} ->
        Logger.error("Failed to start deployment scope #{inspect(err)}")
        {:error, err}

      err ->
        Logger.error("Failed to start deployment scope #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Spawn new stack manager service.
  Helpful for dynamically starting new stacks for existing chains that are already running
  """
  @spec spawn_stack_manager(binary, binary) :: DynamicSupervisor.on_start_child()
  def spawn_stack_manager(scope_id, stack_name),
    do: DeploymentScopeSupervisor.start_stack_manager(scope_id, stack_name)

  @doc """
  Stop stack manager service
  Will terminate all containers/resources binded to stack
  """
  @spec stop_stack_manager(binary, binary) :: :ok
  def stop_stack_manager(scope_id, stack_name),
    do: StackManager.stop(scope_id, stack_name)

  @doc """
  Stop supervision tree for deployment scope with given ID
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(id),
    do: ScopesSupervisor.stop_scope(id)

  @doc """
  Check if given deployment scope is alive
  """
  @spec alive?(binary) :: boolean
  def alive?(id) do
    id
    |> DeploymentScopeSupervisor.via_tuple()
    |> GenServer.whereis()
    |> case do
      nil ->
        false

      pid ->
        Process.alive?(pid)
    end
  end

  @doc """
  Starting new container for given stack id
  """
  @spec start_container(binary, binary, Container.t()) :: {:ok, Container.t()} | {:error, term}
  def start_container(id, stack_name, %Container{name: ""} = container),
    do: start_container(id, stack_name, %Container{container | name: Docker.random_name()})

  def start_container(id, stack_name, %Container{network: ""} = container),
    do: start_container(id, stack_name, %Container{container | network: id})

  def start_container(id, stack_name, %Container{image: image} = container) do
    with {:alive, true} <- {:alive, StackManager.alive?(id, stack_name)},
         {:image, true} <- {:image, ConfigLoader.has_image?(stack_name, image)},
         {:ok, _pid} <- StackManager.start_container(id, stack_name, container) do
      {:ok, container}
    else
      {:alive, _} ->
        Logger.error("Stack #{id}: No active stack found for starting new container")
        {:error, "failed to find stack with id #{id} & name: #{stack_name}"}

      {:image, _} ->
        Logger.error("Stack #{id}: No image #{image} is allowed for stack #{stack_name}")
        {:error, "#{image} image is not allowed for stack #{stack_name}"}

      err ->
        Logger.error("Stack #{id}: failed to start container #{image} with err: #{inspect(err)}")
        {:error, "failed to start image"}
    end
  end

  @doc """
  Get deployment scope details
  """
  @spec info(binary) :: term
  def info(id) do
    case alive?(id) do
      false ->
        []

      true ->
        id
        |> DeploymentScopeSupervisor.get_stack_manager_supervisor()
        |> Supervisor.which_children()
        |> Enum.filter(fn {_, _, _, mods} -> mods == [StackManager] end)
        |> Enum.map(fn {_, pid, :worker, _} -> pid end)
        |> Enum.map(&StackManager.info/1)
        |> List.flatten()
    end
  end

  @doc """
  Load list of all available deployment scopes in system
  """
  @spec list() :: [map]
  def list() do
    # ScopesSupervisor
    # |> Supervisor.which_children()
    # |> Enum.map(fn {_, pid, :supervisor, _} -> pid end)
    # |> IO.inspect()

    []
  end

  @doc """
  Force system to reload all stacks configs
  """
  @spec reload_config() :: :ok
  def reload_config(),
    do: ConfigLoader.reload()

  # Validate if all stacks are allowed to start
  defp validate_stacks([]), do: :ok

  defp validate_stacks(list) do
    result =
      list
      |> Enum.reject(&(&1 == "testchain"))
      |> Enum.filter(fn stack_name -> ConfigLoader.get(stack_name) == nil end)

    case result do
      [] ->
        :ok

      list ->
        {:error, "Not all stacks are allowed to be started ! #{inspect(list)}"}
    end
  end

  # Get list of stack names that need to be started
  defp get_stack_names(params) when is_map(params) do
    params
    |> Map.keys()
    |> Enum.reject(&(&1 == "testchain"))
    |> Enum.reject(&(&1 == ""))
  end
end
