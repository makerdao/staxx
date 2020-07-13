defmodule Staxx.Environment.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, keys: :unique, name: Staxx.Environment.EnvironmentRegistry},
      {Registry, keys: :unique, name: Staxx.Environment.StackRegistry},
      Staxx.Environment.Terminator,
      Staxx.Environment.DynamicSupervisor,
      Staxx.Environment.Stack.ConfigLoader
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Staxx.Environment.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
