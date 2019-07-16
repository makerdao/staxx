defmodule DeploymentScope do
  @moduledoc """
  DeploymentScope is responsible for  aggregation of chain + stacks in one scope
  It handle and manage starting chain/stacks in correct order and validation
  """

  require Logger

  alias Proxy.Chain.ChainHelper
  alias Docker.Struct.Container
  alias DeploymentScope.ScopesSupervisor
  alias DeploymentScope.Scope.SupervisorTree
  alias DeploymentScope.Scope.StackManager
  alias Stacks.ConfigLoader

  @doc """
  Start new deployment scope using given configuration
  """
  @spec start(map) :: {:ok, binary} | {:error, term}
  def start(%{"testchain" => %{"config" => %{"id" => id}}} = params) do
    stacks = Map.drop(params, ["testchain"])

    Logger.debug(fn ->
      """
      Starting deployment scope with existing chain #{id}
      Config:
      #{inspect(stacks, pretty: true)}
      """
    end)

    start(id, id, stacks)
  end

  def start(%{"testchain" => %{"config" => config}} = params) do
    %{id: id} =
      chain_config =
      config
      |> ChainHelper.chain_config_from_payload()
      |> Proxy.new_chain_config!()

    stacks = Map.drop(params, ["testchain"])

    Logger.debug(fn ->
      """
      Starting deployment scope with new chain
      Chain configuration:
      #{inspect(chain_config, pretty: true)}

      Config:
      #{inspect(stacks, pretty: true)}
      """
    end)

    start(id, chain_config, stacks)
  end

  @doc """
  Start supervision tree for new deployment scope
  """
  @spec start(binary, binary | map, map) :: {:ok, binary} | {:error, term}
  def start(id, chain_config, stacks) when is_binary(id) do
    modules = Stacks.get_stack_names(stacks)
    Logger.debug("Starting new deployment scope with modules: #{inspect(modules)}")

    with :ok <- Stacks.validate(modules),
         {:ok, pid} <- ScopesSupervisor.start_scope({id, chain_config, stacks}) do
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

  def start(_, _),
    do: {:error, "wrong chain config"}

  @doc """
  Stop supervision tree for deployment scope with given ID
  """
  @spec stop(binary) :: :ok
  def stop(id) do
    id
    |> SupervisorTree.via_tuple()
    |> Supervisor.stop(:normal)
  end

  @doc """
  Check if given deployment scope is alive
  """
  @spec alive?(binary) :: boolean
  def alive?(id) do
    id
    |> SupervisorTree.via_tuple()
    |> GenServer.whereis()
    |> Process.alive?()
  end

  @doc """
  Starting new container for given stack id
  """
  @spec start_container(binary, binary, Container.t()) :: :ok | {:error, term}
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
    id
    |> SupervisorTree.via_tuple()
    |> Supervisor.which_children()
    |> Enum.filter(fn {module, _, :worker, _} -> module == StackManager end)
    |> Enum.map(fn {_, pid, :worker, _} -> pid end)
    |> Enum.map(&StackManager.info/1)
    |> List.flatten()
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
    do: Stacks.ConfigLoader.reload()
end
