defmodule Staxx.SnapshotRegistry.Controllers.Session do
  @moduledoc """
  Session controller
  """

  use Plug.Router

  alias Staxx.SnapshotRegistry.JwtAuthToken

  plug(:match)
  plug(:dispatch)

  post "/sign_in" do
    send_resp(conn, 200, JwtAuthToken.encode(%{}))
  end
end
