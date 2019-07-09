defmodule DeploymentScope.ScopesSupervisor do
  @moduledoc """
  Supervisor that will manage all deployment scopes
  """

  # Automatically defines child_spec/1
  use DynamicSupervisor

  alias DeploymentScope.Scope.SupervisorTree

  @doc false
  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)
  end

  @doc """
  Start new supervision tree for deployment scope.

  System will start new supervision tree with all required modules in correct order
  For more details see `DeploymentScope.Scope.Supervisor`
  """
  @spec start_scope({binary, binary | map, map}) :: DynamicSupervisor.on_start_child()
  def start_scope({_id, _chain, _stacks} = params),
    do: DynamicSupervisor.start_child(__MODULE__, {SupervisorTree, params})

  def stop_scope(id) when is_binary(id),
    do: DynamicSupervisor.terminate_child(__MODULE__, SupervisorTree.via_tuple(id))
end
