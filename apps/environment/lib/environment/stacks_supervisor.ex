defmodule Staxx.Environment.StacksSupervisor do
  @moduledoc """
  Supervises `Stack`s for environment.
  """
  use DynamicSupervisor

  alias Staxx.Environment.Stack

  @doc false
  def child_spec(id) do
    %{
      id: "stack_manager_supervisor_#{id}",
      start: {__MODULE__, :start_link, [id]},
      restart: :temporary,
      type: :supervisor
    }
  end

  @doc """
  Start a new supervisor for manage `Stack`s.
  """
  @spec start_link(binary) :: Supervisor.on_start()
  def start_link(environment_id),
    do: DynamicSupervisor.start_link(__MODULE__, environment_id)

  @impl true
  def init(_init_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)

  @doc """
  Start new supervised `Stack` pid under given supervidor.
  """
  @spec start_manager(pid, binary, binary) :: DynamicSupervisor.on_start_child()
  def start_manager(nil, _, _),
    do: {:error, :no_supervisor_given}

  def start_manager(supervisor_pid, environment_id, stack_name) do
    supervisor_pid
    |> DynamicSupervisor.start_child(Stack.child_spec(environment_id, stack_name))
  end
end
