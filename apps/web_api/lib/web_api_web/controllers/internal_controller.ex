defmodule WebApiWeb.InternalController do
  use WebApiWeb, :controller
  require Logger

  alias Proxy.Deployment.ServiceList

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
  def rpc(conn, %{"method" => "RunResult", "data" => data}) do
    Logger.info("Request id #{Map.get(data, "id")}, method: RunResult data #{inspect(data)}")
    process_deployment_result(data)

    conn
    |> json(%{type: "ok"})
  end

  @doc false
  def rpc(conn, %{"id" => id, "method" => method, "data" => data}) do
    Logger.info("Request #{id} with method: #{method}")
    IO.inspect(data)

    conn
    |> json(%{type: "ok"})
  end

  # TODO: Add error handling

  defp process_deployment_result(%{"id" => id, "type" => "error", "result" => result}) do
    case Proxy.Deployment.ProcessWatcher.pop(id) do
      nil ->
        Logger.debug("No process found that want to handle deployment request with id: #{id}")

      chain_id when is_binary(chain_id) ->
        Logger.debug("Chain #{chain_id} need to handle deployment request")
        Proxy.Chain.Worker.handle_deployment_failure(chain_id, id, result)

      _ ->
        Logger.error("Something wrong with fetching deployemnt result #{id}")
    end
  end

  defp process_deployment_result(%{"id" => id, "type" => "ok", "result" => %{"data" => data}}) do
    case Proxy.Deployment.ProcessWatcher.pop(id) do
      nil ->
        Logger.debug("No process found that want to handle deployment request with id: #{id}")

      chain_id when is_binary(chain_id) ->
        Logger.debug("Chain #{chain_id} need to handle deployment request")
        Proxy.Chain.Worker.handle_deployment(chain_id, id, data)

      _ ->
        Logger.error("Something wrong with fetching deployemnt result #{id}")
    end
  end
end
