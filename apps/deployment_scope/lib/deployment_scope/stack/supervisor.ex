defmodule DeploymentScope.StackSupervisor do
  @moduledoc """
  This supervisor is an owner of list of stack containers.
  It starts with stack name and will supervise list of containers.
  """
  use Supervisor

  require Logger

  @doc false
  def child_spec(stack_name) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [stack_name]},
      restart: :temporary,
      type: :supervisor
    }
  end

  @doc """
  Start new stack supervisor for application
  """
  @spec start_link(binary) :: Supervisor.on_start()
  def start_link(stack_name),
    do: Supervisor.start_link(__MODULE__, stack_name)

  @impl true
  def init(stack_name) do
    Logger.debug(fn -> "Starting new supervisor for stack with name: #{stack_name}" end)

    # TODO: start manager container
    # get stack config
    # create new worker with manager
    # add functions for starting additional containers
    children = []
    opts = [strategy: :one_for_all, max_restarts: 0]
    Supervisor.init(children, opts)
  end
end
