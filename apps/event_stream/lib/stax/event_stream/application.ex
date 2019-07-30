defmodule Staxx.EventStream.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [] ++ nats_child_specs()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Staxx.EventStream.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp nats_child_specs() do
    :event_stream
    |> Application.get_env(:disable_nats, false)
    |> build_nats_child_specs()
  end

  defp build_nats_child_specs(true),
    do: []

  defp build_nats_child_specs(false),
    do: [{Staxx.EventStream.NatsPublisher, []}]
end
