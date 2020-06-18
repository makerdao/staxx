defmodule Staxx.WebApiWeb.ExtensionController do
  use Staxx.WebApiWeb, :controller

  require Logger

  action_fallback(Staxx.WebApiWeb.FallbackController)

  alias Staxx.Environment
  alias Staxx.EventStream.Notification
  alias Staxx.Environment.Extension
  alias Staxx.Environment.Extension.ConfigLoader

  alias Staxx.WebApiWeb.SuccessView

  # List of available extension configs
  def list_config(conn, _params) do
    with {:ok, list} <- {:ok, ConfigLoader.get()} do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: list)
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

  def start(conn, %{
        "environment_id" => environment_id,
        "extension_name" => extension_name
      }) do
    with {:ok, _} <- Environment.start_extension(environment_id, extension_name) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  def stop(conn, %{
        "environment_id" => environment_id,
        "extension_name" => extension_name
      }) do
    with :ok <- Environment.stop_extension(environment_id, extension_name) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send notification to extension
  def notify(conn, %{
        "environment_id" => environment_id,
        "event" => event,
        "data" => data
      }) do
    with true <- Environment.alive?(environment_id),
         :ok <- Notification.notify(environment_id, event, data) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send extension ready notification
  def notify_ready(conn, %{"environment_id" => environment_id, "extension_name" => extension}) do
    with :ok <- Extension.set_status(environment_id, extension, :ready) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send extension failed notification
  def notify_failed(conn, %{"environment_id" => environment_id, "extension_name" => extension}) do
    with :ok <- Extension.set_status(environment_id, extension, :failed) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end
end
