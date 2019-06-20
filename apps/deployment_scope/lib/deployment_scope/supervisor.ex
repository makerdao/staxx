defmodule DeploymentScope.Supervisor do
  @moduledoc """
  Supervisor that will manage all deployment scopes
  """

  # Automatically defines child_spec/1
  use DynamicSupervisor

  @doc false
  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start new supervision tree for deployment scope.

  System will start new supervision tree with all required modules in correct order
  For more details see `DeploymentScope.Scope.Supervisor`
  """
  @spec start_scope({binary, binary | map, map}) :: DynamicSupervisor.on_start_child()
  def start_scope({_id, _chain, _stacks} = params) do
    child_spec = %{
      start: {DeploymentScope.Scope.Supervisor, :start_link, [params]},
      restart: :temporary,
      type: :supervisor
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
