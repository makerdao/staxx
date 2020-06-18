defmodule Staxx.WebApiWeb.DockerController do
  use Staxx.WebApiWeb, :controller

  require Logger

  action_fallback Staxx.WebApiWeb.FallbackController

  alias Staxx.WebApiWeb.SuccessView
  alias Staxx.WebApiWeb.ErrorView
  alias Staxx.Docker
  alias Staxx.Docker.Container
  alias Staxx.Environment
  alias Staxx.WebApiWeb.Schemas.DockerSchema

  def start(conn, %{"extension_id" => id, "extension_name" => extension_name} = params) do
    # We wouldn't let users to control `rm` flag for container
    # Otherwise we will have a log of dead containers in our system

    with :ok <- DockerSchema.validate(params),
         container <- Container.create_container(params, id),
         {:ok, container} <- Environment.start_container(id, extension_name, container) do
      Logger.debug("Extension #{id} Starting new docker container #{inspect(container)}")

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

  defp encode(%Container{ports: ports} = container) do
    updated_ports =
      ports
      |> Enum.map(&make_port/1)

    %Container{container | ports: updated_ports}
  end

  defp make_port({port, _}), do: port
  defp make_port(port), do: port
end
