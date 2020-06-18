defmodule Staxx.Transport.ListenerSupervisor do
  @moduledoc """
  Dynamic supervisor for `Staxx.Transport.ListenerWorker` workers.
  """
  use DynamicSupervisor

  @doc false
  def start_link(args \\ %{}),
    do: DynamicSupervisor.start_link(__MODULE__, args)

  @impl true
  @doc false
  def init(_args), do: DynamicSupervisor.init(strategy: :one_for_one)

  @doc """
  Starts `Staxx.Transport.ListenerWorker` worker, passes given socket in to it and adds it to supervisor.
  Sets added child worker as a controlling proccess for a given socket.
  Returns `{:ok, child_pid}` where child_pid is pid of child task.
  """
  @spec start_listener(pid(), port, tuple()) :: {:ok, pid()}
  def start_listener(supervisor_pid, socket, args) do
    {:ok, child_pid} =
      DynamicSupervisor.start_child(
        supervisor_pid,
        {Staxx.Transport.ListenerWorker, Tuple.insert_at(args, 0, socket)}
      )

    :gen_tcp.controlling_process(socket, child_pid)
    {:ok, child_pid}
  end
end
