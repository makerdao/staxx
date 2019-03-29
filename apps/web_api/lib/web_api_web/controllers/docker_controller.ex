defmodule WebApiWeb.DockerController do
  use WebApiWeb, :controller

  require Logger

  action_fallback WebApiWeb.FallbackController

  alias WebApiWeb.SuccessView
  alias WebApiWeb.ErrorView

  def start(conn, %{"stack_id" => id, "stack_name" => stack_name} = params) do
    container = %Docker.Struct.Container{
      image: Map.get(params, "image", ""),
      name: Map.get(params, "name", ""),
      network: Map.get(params, "network", id),
      ports: Map.get(params, "ports", []),
      env: parse_env(Map.get(params, "env", %{}))
    }

    Logger.debug("Stack #{id} Starting new docker container #{inspect(container)}")

    with {:ok, container} <- Stacks.start_container(id, stack_name, container) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: container)
    end
  end

  def stop(conn, %{"id" => id}) do
    case Proxy.Chain.Docker.stop(id) do
      {:ok, _id} ->
        conn
        |> put_status(200)
        |> put_view(SuccessView)
        |> render("200.json", data: "ok")

      {:error, err} ->
        conn
        |> put_status(500)
        |> put_view(ErrorView)
        |> render("500.json", message: err)
    end
  end

  defp parse_env(map) when is_map(map), do: map
  defp parse_env(_some), do: %{}
end
