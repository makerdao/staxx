defmodule Staxx.WebApiWeb.Api.V1.FallbackController do
  use Phoenix.Controller
  require Logger

  alias Staxx.WebApiWeb.Api.V1.ErrorView

  def call(conn, {:error, :no_chain_connected}) do
    Logger.error(fn -> "No connectivity to ex_testchain !" end)

    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("500.json", message: "No ex_testchain service connected. Please contact support !")
  end

  def call(conn, {:error, msg}) when is_binary(msg) do
    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("500.json", message: msg)
  end

  def call(conn, {:error, errors}) when is_list(errors) do
    # json schema validator returns list of validation errors in tuples {error_msg, property_name}
    {error_msg, property_name} = List.first(errors)
    msg = error_msg <> " " <> property_name

    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("500.json", message: msg)
  end

  def call(conn, false) do
    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("404.json", message: "Not found")
  end

  def call(conn, nil) do
    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("404.json", message: "Not found")
  end

  def call(conn, error) do
    Logger.error(fn ->
      """
      Unknown error catched in FallbackController:
      #{inspect(error, pretty: true)}
      """
    end)

    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("500.json", message: "Unknown error")
  end
end
