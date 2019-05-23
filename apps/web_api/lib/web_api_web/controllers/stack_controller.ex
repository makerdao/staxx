defmodule WebApiWeb.StackController do
  use WebApiWeb, :controller

  require Logger

  action_fallback WebApiWeb.FallbackController

  alias Proxy.Chain.Worker.Notification

  alias WebApiWeb.SuccessView

  alias WebApi.Utils

  def list(conn, _params) do
    with {:ok, list} <- Stacks.list() do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: list)
    end
  end

  # Start new stack
  def start(conn, %{"testchain" => %{"config" => %{"id" => id}}} = params) do
    Logger.debug("#{__MODULE__}: New stack is starting using existing testchain: #{id}")

    with {:ok, id} <- Stacks.start(id, params) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{id: id})
    end
  end

  def start(conn, %{"testchain" => %{"config" => chain_config}} = params) do
    Logger.debug("#{__MODULE__}: New stack is starting")
    config = Utils.chain_config_from_payload(chain_config)

    with {:ok, id} <- Stacks.start(config, params) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{id: id})
    end
  end

  # Stop stack
  def stop(conn, %{"id" => id}) do
    Logger.debug("#{__MODULE__}: Stopping stack #{id}")

    with :ok <- Stacks.stop(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  def info(conn, %{"id" => id}) do
    Logger.debug("#{__MODULE__}: Loading stack #{id} details")

    with urls <- Stacks.info(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{urls: urls})
    end
  end

  # Send notification to stack
  def notify(conn, %{"id" => id, "event" => event, "data" => data}) do
    with true <- Stacks.alive?(id),
         :ok <- Notification.send_to_event_bus(id, event, data) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send stack ready notification
  def stack_ready(conn, %{"id" => id, "stack_name" => stack} = payload) do
    data = %{
      stack_name: stack,
      data: Map.get(payload, "data", %{})
    }

    with true <- Stacks.alive?(id),
         :ok <- Notification.send_to_event_bus(id, "stack:ready", data) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  # Send stacl failed notification
  def stack_failed(conn, %{"id" => id, "stack_name" => stack} = payload) do
    details = %{
      stack_name: stack,
      data: Map.get(payload, "data", %{})
    }

    with true <- Stacks.alive?(id),
         :ok <- Notification.send_to_event_bus(id, "stack:failed", details) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end
end
