defmodule Staxx.DeploymentScope.Scope.StackManagerSupervisor do
  @moduledoc """
  This supervisor will take care of list of available stacks
  """
  use DynamicSupervisor

  alias Staxx.DeploymentScope.Scope.StackManager

  @doc """
  Start a new supervisor for manage StackManagers
  """
  @spec start_link(binary) :: Supervisor.on_start()
  def start_link(scope_id) do
    DynamicSupervisor.start_link(__MODULE__, scope_id)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)
  end

  @doc """
  Start new supervised StackManager pid under given supervidor
  """
  @spec start_manager(pid, binary, binary) :: DynamicSupervisor.on_start_child()
  def start_manager(nil, _, _), do: {:error, :no_supervisor_given}

  def start_manager(supervisor_pid, scope_id, stack_name) do
    supervisor_pid
    |> DynamicSupervisor.start_child(StackManager.child_spec(scope_id, stack_name))
  end
end
