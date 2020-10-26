defmodule Staxx.WebApiWeb.InstancesControllerCase do
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
      use Phoenix.ConnTest

      alias Staxx.WebApiWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint Staxx.WebApiWeb.Endpoint
    end
  end

  import Staxx.Store.Factory

  setup_all _ do
    # Remove all users
    Staxx.Store.Repo.delete_all(Staxx.Store.Models.User)

    # Create user with email from test config
    {:ok, %Staxx.Store.Models.User{} = user} =
      Staxx.Store.Models.User.create(%{
        email: Application.get_env(:web_api, :test_user_email, "test@test.com"),
        admin: true,
        active: true,
        name: Faker.Name.name()
      })

    # Remove all chains
    Staxx.Store.Repo.delete_all(Staxx.Store.Models.Chain)

    # Create chains for user we created before
    [
      %{
        id: "1234567890",
        title: Faker.Name.name(),
        node_type: "geth",
        user_id: user.id
      },
      %{
        id: Faker.UUID.v4(),
        title: Faker.Name.name(),
        node_type: "geth",
        user_id: user.id
      },
      %{
        id: Faker.UUID.v4(),
        title: Faker.Name.name(),
        node_type: "geth",
        user_id: user.id
      }
    ]
    |> Enum.each(fn item -> Staxx.Store.Models.Chain.create(item) end)

    # Remove all snapshots
    Staxx.Store.Testchain.SnapshotsStore.remove_all()

    [
      build_snapshot_details(:geth),
      build_snapshot_details(:geth),
      build_snapshot_details(:geth)
    ]
    |> Enum.each(fn snapshot -> Staxx.Store.Testchain.SnapshotsStore.store(snapshot) end)

    :ok
  end

  setup _tags do
    email = Application.get_env(:web_api, :test_user_email, "test@test.com")

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("x-user-email", email)

    {:ok, conn: conn}
  end
end
