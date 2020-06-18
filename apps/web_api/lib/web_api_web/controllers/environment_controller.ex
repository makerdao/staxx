defmodule Staxx.WebApiWeb.EnvironmentController do
  use Staxx.WebApiWeb, :controller

  require Logger

  action_fallback(Staxx.WebApiWeb.FallbackController)

  alias Staxx.Environment
  alias Staxx.EventStream.Notification
  alias Staxx.Environment.Extension
  alias Staxx.Environment.Extension.ConfigLoader
  alias Staxx.WebApiWeb.Schemas.TestchainSchema

  alias Staxx.WebApiWeb.SuccessView

  # List of available extension configs
  def list(conn, _params) do
    with {:ok, list} <- {:ok, ConfigLoader.get()} do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: list)
    end
  end

  def start(conn, %{"testchain" => _} = params) do
    Logger.debug("#{__MODULE__}: New environment is starting")

    with :ok <- TestchainSchema.validate_with_payload(params),
         {:ok, id} <- Environment.start(params, get_user_email(conn)) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{id: id})
    end
  end

  def stop(conn, %{"id" => id}) do
    Logger.debug("#{__MODULE__}: Stopping environment #{id}")

    with :ok <- Environment.stop(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  def info(conn, %{"id" => id}) do
    Logger.debug("#{__MODULE__}: Loading environment #{id} details")

    with data <- Environment.info(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: data)
    end
  end

  def spawn_extension_manager(conn, %{"id" => id, "extension_name" => name}) do
    with {:ok, _} <- Environment.spawn_extension_manager(id, name) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  def stop_extension_manager(conn, %{"id" => id, "extension_name" => name}) do
    with :ok <- Environment.stop_extension_manager(id, name) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send notification to extension
  def notify(conn, %{"id" => id, "event" => event, "data" => data}) do
    with true <- Environment.alive?(id),
         :ok <- Notification.notify(id, event, data) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send extension ready notification
  def extension_ready(conn, %{"id" => id, "extension_name" => extension}) do
    with :ok <- Extension.set_status(id, extension, :ready) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send extension failed notification
  def extension_failed(conn, %{"id" => id, "extension_name" => extension}) do
    with :ok <- Extension.set_status(id, extension, :failed) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Force to reload config
  def reload_config(conn, _) do
    with :ok <- Environment.reload_config() do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end
end
