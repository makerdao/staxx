defmodule Staxx.DeploymentScope.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, keys: :unique, name: Staxx.DeploymentScope.ScopeRegistry},
      {Registry, keys: :unique, name: Staxx.DeploymentScope.StackRegistry},
      # TODO: Check if it's needed here
      {Registry, keys: :unique, name: Staxx.DeploymentScope.EVMWorkerRegistry},
      Staxx.DeploymentScope.ScopesSupervisor,
      Staxx.DeploymentScope.Stack.ConfigLoader,
      # User <-> Chain mapper, DETS based GenServer
      Staxx.DeploymentScope.UserScope,
      # EVM & deployment integration
      Staxx.DeploymentScope.EVMWorker.Storage,
      Staxx.DeploymentScope.Deployment.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Staxx.DeploymentScope.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
