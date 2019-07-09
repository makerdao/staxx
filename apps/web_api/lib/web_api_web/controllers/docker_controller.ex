defmodule WebApiWeb.DockerController do
  use WebApiWeb, :controller

  require Logger

  action_fallback WebApiWeb.FallbackController

  alias WebApiWeb.SuccessView
  alias WebApiWeb.ErrorView
  alias Docker.Struct.Container

  def start(conn, %{"stack_id" => id, "stack_name" => stack_name} = params) do
    container = %Container{
      image: Map.get(params, "image", ""),
      name: Map.get(params, "name", ""),
      network: Map.get(params, "network", id),
      ports: Map.get(params, "ports", []),
      env: parse_env(Map.get(params, "env", %{}))
    }

    Logger.debug("Stack #{id} Starting new docker container #{inspect(container)}")

    with {:ok, container} <- DeploymentScope.start_container(id, stack_name, container) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: encode(container))
    end
  end

  def stop(conn, %{"id" => id}) do
    case Docker.stop(id) do
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

  defp encode(%Container{ports: ports} = container) do
    updated_ports =
      ports
      |> Enum.map(&make_port/1)

    %Container{container | ports: updated_ports}
  end

  defp make_port({port, _}), do: port
  defp make_port(port), do: port
end
