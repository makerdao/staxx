defmodule Staxx.DeploymentScope.Scope.DeploymentScopeSupervisor do
  @moduledoc """
  Deployment scope supervisor.
  It controll specific scope for user.

  Part of is will be:
   - chain - Exact EVM that will be started for scope
   - list of stacks - set of stack workers that control different stacks
  """
  use Supervisor

  require Logger

  alias Staxx.DeploymentScope
  alias Staxx.DeploymentScope.Scope.StackManagerSupervisor
  alias Staxx.DeploymentScope.ScopeRegistry
  alias Staxx.Testchain.Supervisor, as: TestchainSupervisor

  @doc false
  def child_spec({id, _, _} = params) do
    %{
      id: "deployment_scope_supervisor_#{id}",
      start: {__MODULE__, :start_link, [params]},
      restart: :temporary,
      type: :supervisor
    }
  end

  @doc """
  Start new supervision tree for newly created deployment scope
  """
  def start_link({id, _chain_config_or_id, stacks} = params) do
    res = Supervisor.start_link(__MODULE__, params, name: via_tuple(id))

    # have to start stack managers here. Because need to be sure that testchain
    # already started, before starting stacks.
    case res do
      {:ok, _} ->
        start_stack_managers(id, stacks)
        res

      _ ->
        res
    end
  end

  @impl true
  def init({id, chain_config_or_id, _stacks}) do
    children = [
      TestchainSupervisor.child_spec({id, chain_config_or_id}),
      StackManagerSupervisor.child_spec(id)
    ]

    opts = [strategy: :rest_for_one, max_restarts: 0]
    Supervisor.init(children, opts)
  end

  @doc """
  Generate naming via tuple for supervisor
  """
  @spec via_tuple(binary) :: {:via, Registry, {ScopeRegistry, binary}}
  def via_tuple(id),
    do: {:via, Registry, {ScopeRegistry, id}}

  @doc """
  Get StackManagerSupervisor instance binded to this stack
  """
  @spec get_stack_manager_supervisor(binary) :: pid | nil
  def get_stack_manager_supervisor(scope_id) do
    res =
      scope_id
      |> via_tuple()
      |> Supervisor.which_children()
      |> Enum.find(nil, fn {module, _pid, _, _} -> module == StackManagerSupervisor end)

    case res do
      {_, pid, _, _} ->
        pid

      _ ->
        nil
    end
  end

  @doc """
  Start new stack manager for deployment scope.
  """
  @spec start_stack_manager(binary, binary) :: DynamicSupervisor.on_start_child()
  def start_stack_manager(scope_id, stack_name) do
    case DeploymentScope.alive?(scope_id) do
      false ->
        {:error, "No working stack with such id"}

      true ->
        scope_id
        |> get_stack_manager_supervisor()
        |> StackManagerSupervisor.start_manager(scope_id, stack_name)
    end
  end

  # Start list of stack managers
  defp start_stack_managers(scope_id, stacks) do
    stacks
    |> Map.keys()
    |> Enum.uniq()
    |> Enum.map(&start_stack_manager(scope_id, &1))
  end
end
