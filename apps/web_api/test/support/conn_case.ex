defmodule Staxx.WebApiWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Staxx.WebApiWeb.UserFactory

      alias Staxx.WebApiWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint Staxx.WebApiWeb.Endpoint
    end
  end

  setup _tags do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header(
        "x-user-email",
        Application.get_env(:web_api, :test_email, "test@test.com")
      )

    {:ok, conn: conn}
  end
end
