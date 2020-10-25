defmodule Staxx.Instance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, keys: :unique, name: Staxx.Instance.InstanceRegistry},
      {Registry, keys: :unique, name: Staxx.Instance.StackRegistry},
      Staxx.Instance.Terminator,
      Staxx.Instance.DynamicSupervisor,
      Staxx.Instance.Stack.ConfigLoader
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Staxx.Instance.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
