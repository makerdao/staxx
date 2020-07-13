defmodule Staxx.WebApiWeb.EnvironmentControllerTest do
  @moduledoc """
  Tests for ChainController.
  See apps/store/priv/repo/seeds.exs for information about test data in db.
  """
  use Staxx.WebApiWeb.EnvironmentControllerCase

  @moduletag :api
  
  describe "Environment tests::" do
    test "should return list of chains belongs to user", %{conn: conn} do
      assert %{"data" => chains, "errors" => [], "status" => 0} =
               conn
               |> get(Routes.environment_path(conn, :list))
               |> json_response(200)

      assert length(chains) == 3
    end

    test "should return chain details", %{conn: conn} do
      id = "1234567890"

      %{"data" => %{"testchain" => %{"id" => chain_id, "node_type" => node_type}}} =
        conn
        |> get(Routes.environment_path(conn, :info, id))
        |> json_response(200)

      assert id == chain_id
      assert node_type == "geth"
    end

    test "should return 404 code status", %{conn: conn} do
      id = Faker.UUID.v4()

      conn
      |> get(Routes.environment_path(conn, :info, id))
      |> json_response(404)
    end
  end
end
