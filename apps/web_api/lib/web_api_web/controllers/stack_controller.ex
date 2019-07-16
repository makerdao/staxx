defmodule WebApiWeb.StackController do
  use WebApiWeb, :controller

  require Logger

  action_fallback WebApiWeb.FallbackController

  alias Proxy.Chain.Notification
  alias DeploymentScope.Scope.StackManager

  alias WebApiWeb.SuccessView

  def list(conn, _params) do
    with {:ok, list} <- {:ok, DeploymentScope.list()} do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: list)
    end
  end

  def start(conn, %{"testchain" => _} = params) do
    Logger.debug("#{__MODULE__}: New stack is starting")

    with {:ok, id} <- DeploymentScope.start(params) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{id: id})
    end
  end

  # Stop stack
  def stop(conn, %{"id" => id}) do
    Logger.debug("#{__MODULE__}: Stopping stack #{id}")

    with :ok <- DeploymentScope.stop(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  def info(conn, %{"id" => id}) do
    Logger.debug("#{__MODULE__}: Loading stack #{id} details")

    with data <- DeploymentScope.info(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: data)
    end
  end

  # Send notification to stack
  def notify(conn, %{"id" => id, "event" => event, "data" => data}) do
    with true <- DeploymentScope.alive?(id),
         :ok <- Notification.send_to_event_bus(id, event, data) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send stack ready notification
  def stack_ready(conn, %{"id" => id, "stack_name" => stack}) do
    with :ok <- StackManager.set_status(id, stack, :ready) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send stacl failed notification
  def stack_failed(conn, %{"id" => id, "stack_name" => stack}) do
    with :ok <- StackManager.set_status(id, stack, :failed) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end
end
