defmodule Staxx.Metrix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children =
      case Application.get_env(:metrix, :run_prometheus, false) do
        true ->
          Logger.debug(fn -> "Starting Prometheus endpoint on port 9568, route: /metrics" end)

          [
            {TelemetryMetricsPrometheus,
             [metrics: Staxx.Metrix.metrics(), validations: [require_seconds: false]]}
          ]

        _ ->
          []
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Staxx.Metrix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
