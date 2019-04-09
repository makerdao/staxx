defmodule Proxy.Deployment.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Task.Supervisor, name: Proxy.Deployment.TaskSupervisor},
      {Registry, keys: :unique, name: Proxy.Deployment.Registry},
      Proxy.Deployment.StepsFetcher,
      Proxy.Deployment.ServiceList,
      Proxy.Deployment.ProcessWatcher
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
