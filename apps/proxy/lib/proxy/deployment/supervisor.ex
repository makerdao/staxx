defmodule Staxx.Proxy.Deployment.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Task.Supervisor, name: Staxx.Proxy.Deployment.TaskSupervisor},
      {Registry, keys: :unique, name: Staxx.Proxy.DeploymentRegistry},
      Staxx.Proxy.Deployment.StepsFetcher,
      Staxx.Proxy.Deployment.ServiceList,
      Staxx.Proxy.Deployment.ProcessWatcher
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
