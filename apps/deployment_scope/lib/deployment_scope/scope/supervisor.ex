defmodule DeploymentScope.Scope.Supervisor do
  @moduledoc """
  Deployment scope supervisor.
  It controll specific scope for user.

  Part of is will be:
   - chain - Exact EVM that will be started for scope
   - list of stacks - set of stack workers that control different stacks
  """
  use Supervisor

  def start_link(params) do
    # TODO: Need to get ID ?
    # Supervisor.start_link(__MODULE__, params,
    # name: {:via, Registry, {DeploymentScope.ScopeRegistry, id}}
    # )
    Supervisor.start_link(__MODULE__, params)
  end

  @impl true
  def init(params) do
    children = []

    opts = [strategy: :one_for_all, max_restarts: 0]
    Supervisor.init(children, opts)
  end
end
