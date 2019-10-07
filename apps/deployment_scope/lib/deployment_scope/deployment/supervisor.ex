defmodule Staxx.DeploymentScope.Deployment.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Task.Supervisor, name: Staxx.DeploymentScope.Deployment.TaskSupervisor},
      {Registry, keys: :unique, name: Staxx.DeploymentScope.DeploymentRegistry},
      Staxx.DeploymentScope.Deployment.StepsFetcher,
      Staxx.DeploymentScope.Deployment.ServiceList,
      Staxx.DeploymentScope.Deployment.ProcessWatcher
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
