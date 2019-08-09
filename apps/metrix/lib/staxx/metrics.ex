defmodule Staxx.Metrix do
  @moduledoc """
  Modeule that handle list of metrics available for app
  """
  import Telemetry.Metrics

  @doc """
  Get list of metrics that should be exposed to phometheus
  """
  @spec metrics() :: list
  def metrics() do
    vm_metrics() ++
      http_metrics() ++
      chain_metrics()
  end

  # VM metrics
  defp vm_metrics() do
    [
      last_value("vm.memory.total"),
      last_value("vm.memory.processes_used"),
      last_value("vm.memory.ets"),
      last_value("vm.memory.binary"),
      last_value("vm.total_run_queue_lengths.cpu")
    ]
  end

  # List of HTTP layer metrics
  defp http_metrics() do
    [
      counter("http.requests.count", event_name: "staxx.rpc.start"),
      counter("http.responses.count",
        event_name: "staxx.rpc.stop",
        tags: [:status],
        tag_values: &http_reponse_tags/1
      ),
      distribution("http.responses.duration",
        event_name: "staxx.rpc.stop",
        buckets: [100, 200, 300],
        tags: [:status],
        tag_values: &http_reponse_tags/1,
        unit: {:native, :millisecond}
      )
    ]
  end

  # List of DB metrics
  defp chain_metrics() do
    [
      counter("staxx.docker.container.start", event_name: "staxx.docker.start"),
      counter("staxx.docker.container.stop", event_name: "staxx.docker.stop"),
      # Chain events
      counter("staxx.chain.start", event_name: "staxx.chain.start"),
      counter("staxx.chain.stop", event_name: "staxx.chain.stop"),
      counter("staxx.chain.deployment.success", event_name: "staxx.chain.deploy.success"),
      counter("staxx.chain.deployment.failure", event_name: "staxx.chain.deploy.failure")
    ]
  end

  # Get status code
  defp http_reponse_tags(%{conn: conn}) do
    # IO.inspect(conn)
    %{status: conn.status}
  end
end
