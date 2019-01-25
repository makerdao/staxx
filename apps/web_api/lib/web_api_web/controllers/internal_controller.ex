defmodule WebApiWeb.InternalController do
  use WebApiWeb, :controller
  require Logger

  def rpc(conn, %{"id" => id, "method" => method, "data" => data}) do
    Logger.info("Request id #{id}, method #{method}, data #{inspect(data)}")
    case method do
      "RegisterDeployment" -> register_deployment(data)
      "UnregisterDeployment" -> unregister_deployment(data)
      _ -> conn
           |> json(%{type: "error"})
    end
    conn
    |> json(%{type: "ok"})
  end

  defp register_deployment(data) do
    Storage.InMemory.add_deployment(%{host: data["host"], port: data["port"]})
  end

  defp unregister_deployment(data) do
    Storage.InMemory.delete_deployment(%{host: data["host"], port: data["port"]})
  end
end
