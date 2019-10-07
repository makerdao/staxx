defmodule Staxx.WebApiWeb.InternalController do
  use Staxx.WebApiWeb, :controller
  require Logger

  alias Staxx.DeploymentScope.EVMWorker
  alias Staxx.DeploymentScope.Deployment.{Deployer, ProcessWatcher, ServiceList}

  @doc false
  def rpc(conn, %{"id" => id, "method" => "RegisterDeployment", "data" => data}) do
    Logger.info("Request id #{id}, method RegisterDeployment, data #{inspect(data)}")
    ServiceList.add_deployment(%{host: data["host"], port: data["port"]})

    conn
    |> json(%{type: "ok"})
  end

  @doc false
  def rpc(conn, %{"id" => id, "method" => "UnregisterDeployment", "data" => data}) do
    Logger.info("Request id #{id}, method: UnregisterDeployment data #{inspect(data)}")
    ServiceList.delete_deployment(%{host: data["host"], port: data["port"]})

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

  def rpc(conn, %{"method" => "CheckoutResult", "data" => data}) do
    id = Map.get(data, "id")
    Logger.info("Request id #{id}, checkout successfull, data: #{inspect(data)}")
    Deployer.handle(id, {:checkout, data})

    conn
    |> json(%{type: "ok"})
  end

  @doc false
  def rpc(conn, %{"id" => id, "method" => method, "data" => data}) do
    Logger.info("Request #{id} with method: #{method} data: #{inspect(data)}")

    conn
    |> json(%{type: "ok"})
  end

  defp process_deployment_result(%{"id" => id, "type" => "error", "result" => result}) do
    case ProcessWatcher.pop(id) do
      nil ->
        Logger.debug("No process found that want to handle deployment request with id: #{id}")

      chain_id when is_binary(chain_id) ->
        Logger.debug("Chain #{chain_id} need to handle deployment request")
        EVMWorker.handle_deployment_failure(chain_id, id, result)

      _ ->
        Logger.error("Something wrong with fetching deployemnt result #{id}")
    end
  end

  defp process_deployment_result(%{"id" => id, "type" => "ok", "result" => %{"data" => data}}) do
    case ProcessWatcher.pop(id) do
      nil ->
        Logger.debug("No process found that want to handle deployment request with id: #{id}")

      chain_id when is_binary(chain_id) ->
        Logger.debug("Chain #{chain_id} need to handle deployment request")
        EVMWorker.handle_deployment(chain_id, id, data)

      _ ->
        Logger.error("Something wrong with fetching deployemnt result #{id}")
    end
  end
end
