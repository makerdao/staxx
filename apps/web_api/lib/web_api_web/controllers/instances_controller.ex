defmodule Staxx.WebApiWeb.InstancesController do
  use Staxx.WebApiWeb, :controller

  require Logger

  action_fallback(Staxx.WebApiWeb.FallbackController)

  alias Staxx.Instance
  alias Staxx.Store.Models.User, as: UserRecord
  alias Staxx.WebApiWeb.Schemas.TestchainSchema

  alias Staxx.WebApiWeb.SuccessView
  alias Staxx.WebApiWeb.ErrorView

  def start(conn, %{"testchain" => _} = params) do
    Logger.debug(fn -> "#{__MODULE__}: New instance is starting" end)

    with :ok <- TestchainSchema.validate_with_payload(params),
         {:ok, id} <- Instance.start(params, get_user_email(conn)) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{id: id})
    end
  end

  def stop(conn, %{"id" => id}) do
    Logger.debug(fn -> "#{__MODULE__}: Stopping instance #{id}" end)

    with :ok <- Instance.stop(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  def info(conn, %{"id" => id}) do
    Logger.debug(fn -> "#{__MODULE__}: Loading instance #{id} details" end)

    with data when is_map(data) <- Instance.info(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: data)
    else
      nil ->
        conn
        |> put_status(404)
        |> put_view(ErrorView)
        |> render("404.json")
    end
  end

  def list(conn, _) do
    Logger.debug(fn -> "#{__MODULE__}: Loading instances list" end)

    list =
      conn
      |> get_user_email()
      |> UserRecord.get_user_id()
      |> Instance.list()

    conn
    |> put_status(200)
    |> put_view(SuccessView)
    |> render("200.json", data: list)
  end

  def remove(conn, %{"id" => id}) do
    Logger.debug(fn -> "#{__MODULE__}: Removing instance #{id}" end)

    with :ok <- Instance.remove(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end
end
