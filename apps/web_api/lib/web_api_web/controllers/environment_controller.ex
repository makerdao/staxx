defmodule Staxx.WebApiWeb.EnvironmentController do
  use Staxx.WebApiWeb, :controller

  require Logger

  action_fallback(Staxx.WebApiWeb.FallbackController)

  alias Staxx.Environment
  alias Staxx.Store.Models.User, as: UserRecord
  alias Staxx.WebApiWeb.Schemas.TestchainSchema

  alias Staxx.WebApiWeb.SuccessView

  def start(conn, %{"testchain" => _} = params) do
    Logger.debug(fn -> "#{__MODULE__}: New environment is starting" end)

    with :ok <- TestchainSchema.validate_with_payload(params),
         {:ok, id} <- Environment.start(params, get_user_email(conn)) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{id: id})
    end
  end

  def stop(conn, %{"id" => id}) do
    Logger.debug(fn -> "#{__MODULE__}: Stopping environment #{id}" end)

    with :ok <- Environment.stop(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end

  def info(conn, %{"id" => id}) do
    Logger.debug(fn -> "#{__MODULE__}: Loading environment #{id} details" end)

    with data <- Environment.info(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: data)
    end
  end

  def list(conn, _) do
    Logger.debug(fn -> "#{__MODULE__}: Loading environments list" end)

    list =
      conn
      |> get_user_email()
      |> UserRecord.get_user_id()
      |> Environment.list()

    conn
    |> put_status(200)
    |> put_view(SuccessView)
    |> render("200.json", data: list)
  end

  def remove(conn, %{"id" => id}) do
    Logger.debug(fn -> "#{__MODULE__}: Removing environment #{id}" end)

    with :ok <- Environment.remove(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end
end
