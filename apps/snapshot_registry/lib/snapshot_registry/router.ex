defmodule Staxx.SnapshotRegistry.Router do
  @moduledoc """
  SnapshotRegistry router module
  """

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/download", to: Staxx.SnapshotRegistry.Controllers.Download)

  post("/sign_in", to: Staxx.SnapshotRegistry.Controllers.Session)

  match _ do
    send_resp(conn, 404, "Not Found!")
  end
end
