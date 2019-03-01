defmodule WebApiWeb.DockerController do
  use WebApiWeb, :controller

  require Logger

  action_fallback WebApiWeb.FallbackController

  alias WebApiWeb.SuccessView
  alias WebApiWeb.ErrorView

  def start(conn, params) do
    container = %Docker.Struct.Container{
      image: Map.get(params, "image", ""),
      name: Map.get(params, "name", ""),
      ports: Map.get(params, "ports", []),
      env: parse_env(Map.get(params, "env", []))
    }

    Logger.debug("Starting new docker container #{inspect(container)}")
    case Proxy.Chain.Docker.start(container) do
      {:ok, container} ->
        conn
        |> put_status(200)
        |> put_view(SuccessView)
        |> render("200.json", data: container)

      {:error, err} ->
        conn
        |> put_status(500)
        |> put_view(ErrorView)
        |> render("500.json", message: err)
    end
  end

  def stop(conn, %{"id" => id}) do
    IO.inspect(id)
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
