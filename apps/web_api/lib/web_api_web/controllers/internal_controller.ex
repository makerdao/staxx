defmodule WebApiWeb.InternalController do
  use WebApiWeb, :controller

  # Welcome action
  def rpc(conn, _params) do
    conn
    |> json(%{type: "ok"})
  end
end
