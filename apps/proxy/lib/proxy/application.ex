defmodule Proxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Proxy.Worker.start_link(arg)
      # {Proxy.Worker, arg},
      Proxy.Chain.Supervisor,
      Proxy.Chain.Storage,
      Proxy.Deployment.StepsFetcher,
      Proxy.Deployment.ServiceList,
      Proxy.Deployment.ProcessWatcher,
      {Registry, keys: :unique, name: Proxy.ChainRegistry},
      Proxy.NodeManager,
      Proxy.EventBus.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Proxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
