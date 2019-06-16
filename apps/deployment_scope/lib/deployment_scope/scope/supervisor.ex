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
    Supervisor.start_link(__MODULE__, params)
  end

  def init(params) do
  end
end
