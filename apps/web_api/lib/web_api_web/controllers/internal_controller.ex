defmodule Staxx.WebApiWeb.InternalController do
  use Staxx.WebApiWeb, :controller
  require Logger

  alias Staxx.Testchain.Deployment.Worker, as: DeployWorker

  @doc false
  def rpc(conn, %{"id" => id, "method" => "RegisterDeployment", "data" => data}) do
    Logger.info("Request id #{id}, method RegisterDeployment, data #{inspect(data)}")

    conn
    |> json(%{type: "ok"})
  end

  @doc false
  def rpc(conn, %{"id" => id, "method" => "UnregisterDeployment", "data" => data}) do
    Logger.info("Request id #{id}, method: UnregisterDeployment data #{inspect(data)}")

    conn
    |> json(%{type: "ok"})
  end

  @doc false
  def rpc(conn, %{"id" => id, "method" => "UpdateResult", "data" => data}) do
    Logger.info("Request id #{id}, method: UpdateResult data #{inspect(data)}")

    conn
    |> json(%{type: "ok"})
  end

  @doc false
  def rpc(conn, %{"method" => "RunResult", "data" => data}) do
    Logger.info("Request id #{Map.get(data, "id")}, method: RunResult data #{inspect(data)}")
    process_deployment_result(data)

    conn
    |> json(%{type: "ok"})
  end

  # DEPRECATED method handler
  def rpc(conn, %{"method" => "CheckoutResult", "data" => data}) do
    id = Map.get(data, "id")
    Logger.error("DEPRECATED: Request id #{id}, checkout successfull, data: #{inspect(data)}")

    conn
    |> json(%{type: "ok"})
  end

  @doc false
  def rpc(conn, %{"id" => id, "method" => method, "data" => data}) do
    Logger.info("Request #{id} with method: #{method} data: #{inspect(data)}")

    conn
    |> json(%{type: "ok"})
  end

  defp process_deployment_result(%{"id" => id, "type" => "error", "result" => result}),
    do: DeployWorker.deployment_failed(id, result)

  defp process_deployment_result(%{"id" => id, "type" => "ok", "result" => %{"data" => data}}),
    do: DeployWorker.deployment_finished(id, data)
end
