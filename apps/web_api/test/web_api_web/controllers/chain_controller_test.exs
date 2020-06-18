defmodule Staxx.WebApiWeb.ChainControllerTest do
  @moduledoc """
  Tests for ChainController.
  See apps/store/priv/repo/seeds.exs for information about test data in db.
  """
  use Staxx.WebApiWeb.ChainConnCase

  @moduletag :api_chain
  describe "Snapshot tests::" do
    test "new snapshot shouldn't be created because of random id", %{conn: conn} do
      params = %{
        id: Faker.UUID.v4(),
        config: %{
          description: Faker.String.base64()
        }
      }

      assert_raise(
        RuntimeError,
        fn ->
          conn
          |> post(Routes.chain_path(conn, :take_snapshot, params.id), params)
        end
      )
    end

    test "new snapshot shouldn't be created because of json schema validation fail", %{conn: conn} do
      params = %{id: Faker.UUID.v4(), config: %{prprp: Faker.String.base64()}}

      conn
      |> post(Routes.chain_path(conn, :take_snapshot, params.id), params)
      |> json_response(500)
    end

    test "should return list with three `geth` typed snapshot", %{conn: conn} do
      chain_type = "geth"

      %{"data" => snapshots} =
        conn
        |> get(Routes.chain_path(conn, :list_snapshots, chain_type))
        |> json_response(200)

      assert length(snapshots) == 3
      assert [%{"chain" => "geth"}, %{"chain" => "geth"}, %{"chain" => "geth"}] = snapshots
    end

    test "should return empty snaphost list", %{conn: conn} do
      chain_type = Faker.String.base64()

      assert %{"data" => []} =
               conn
               |> get(Routes.chain_path(conn, :list_snapshots, chain_type))
               |> json_response(200)
    end

    test "should return 400 status code for wrong parameters", %{conn: conn} do
      conn
      |> post(Routes.chain_path(conn, :upload_snapshot), %{})
      |> json_response(400)
    end

    test "should return 404 status code for wrong parameters", %{conn: conn} do
      id = Faker.UUID.v4()

      conn
      |> get(Routes.chain_path(conn, :download_snapshot, id))
      |> json_response(404)
    end

    test "remove snapshot always returns 200", %{conn: conn} do
      id = Faker.UUID.v4()

      conn
      |> delete(Routes.chain_path(conn, :remove_snapshot, id))
      |> json_response(200)
    end

    test "snapshot revert should return 500 status code", %{conn: conn} do
      id = Faker.UUID.v4()
      snapshot_id = Faker.UUID.v4()

      conn
      |> post(Routes.chain_path(conn, :revert_snapshot, id, snapshot_id))
      |> json_response(500)
    end
  end

  describe "Chain tests::" do
    test "should return list of chains belongs to user", %{conn: conn} do
      assert %{"data" => chains, "errors" => [], "status" => 0} =
               conn
               |> get(Routes.chain_path(conn, :list_chains))
               |> json_response(200)

      assert length(chains) == 3
    end

    test "should return chain details", %{conn: conn} do
      id = "1234567890"

      %{"data" => %{"id" => chain_id, "node_type" => node_type}} =
        conn
        |> get(Routes.chain_path(conn, :chain_details, id))
        |> json_response(200)

      assert id == chain_id
      assert node_type == "geth"
    end

    test "should return 404 code status", %{conn: conn} do
      id = Faker.UUID.v4()

      conn
      |> get(Routes.chain_path(conn, :chain_details, id))
      |> json_response(404)
    end
  end
end
