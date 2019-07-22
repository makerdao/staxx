defmodule Staxx.WebApiWeb.IndexController do
  use Staxx.WebApiWeb, :controller

  # Welcome action
  def index(conn, _params) do
    conn
    |> json(%{status: 0, message: "Welcome to ExTestchain !"})
  end
end
