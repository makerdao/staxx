defmodule Staxx.WebApiWeb.FallbackController do
  use Phoenix.Controller
  require Logger

  alias Staxx.WebApiWeb.ErrorView

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
end
