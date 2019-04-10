defmodule EventBus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {
        Registry,
        keys: :duplicate, name: LocalPubSub, partitions: System.schedulers_online()
      },
      EventBus.Nats,
      EventBus.Broadcaster,
      EventBus.NatsConsumer,
      EventBus.LocalConsumer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventBus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
