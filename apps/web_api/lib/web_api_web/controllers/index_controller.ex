defmodule Staxx.WebApiWeb.IndexController do
  use Staxx.WebApiWeb, :controller

  alias Staxx.Testchain

  # Welcome action
  def index(conn, _params) do
    conn
    |> json(%{status: 0, message: "Welcome to ExTestchain !"})
  end

  # Get version for binaries and chain
  def version(conn, _) do
    with version when is_binary(version) <- Testchain.version() do
      conn
      |> text(version)
    end
  end
end
