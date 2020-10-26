defmodule Staxx.Instance.StacksSupervisor do
  @moduledoc """
  Supervises list `Stack`s for running Staxx Instance.
  """
  use DynamicSupervisor

  alias Staxx.Instance.Stack

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
  @spec start_link(Instance.id()) :: Supervisor.on_start()
  def start_link(instance_id),
    do: DynamicSupervisor.start_link(__MODULE__, instance_id)

  @impl true
  def init(_init_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)

  @doc """
  Start new supervised `Stack` pid under given supervidor.
  """
  @spec start_manager(pid, Instance.id(), binary) :: DynamicSupervisor.on_start_child()
  def start_manager(nil, _, _),
    do: {:error, :no_supervisor_given}

  def start_manager(supervisor_pid, instance_id, stack_name) do
    supervisor_pid
    |> DynamicSupervisor.start_child(Stack.child_spec(instance_id, stack_name))
  end
end
