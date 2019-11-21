defmodule Staxx.WebApiWeb.UserControllerTest do
  use Staxx.WebApiWeb.ConnCase

  alias Staxx.Store.Models.User

  @tag :web_api
  test "new user should be created", %{conn: conn} do
    user = build(:user)

    %{"status" => 0, "data" => user, "message" => "", "errors" => []} =
      conn
      |> post(Routes.user_path(conn, :create), user)
      |> json_response(200)

    assert Map.get(user, "id", 0) > 0
    assert Map.get(user, "email") == user["email"]
    assert Map.get(user, "name") == user["name"]
  end

  @tag :web_api
  test "list returns created user", %{conn: conn} do
    {:ok, user} =
      :user
      |> build()
      |> User.create()

    %{"status" => 0, "data" => list, "message" => "", "errors" => []} =
      conn
      |> get(Routes.user_path(conn, :list))
      |> json_response(200)

    assert length(list) > 0

    assert 1 ==
             list
             |> Enum.filter(fn %{"id" => id} -> id == user.id end)
             |> length()
  end

  @tag :web_api
  test "get user should load newly created user", %{conn: conn} do
    {:ok, user} =
      :user
      |> build()
      |> User.create()

    %{"status" => 0, "data" => res, "message" => "", "errors" => []} =
      conn
      |> get(Routes.user_path(conn, :get, user.id))
      |> json_response(200)

    assert Map.get(res, "email") == user.email
    assert Map.get(res, "id") == user.id
  end

  @tag :web_api
  test "update user should update instance in db", %{conn: conn} do
    {:ok, user} =
      :user
      |> build()
      |> User.create()

    to_update = build(:user) |> IO.inspect()

    %{"status" => 0, "data" => res, "message" => "", "errors" => []} =
      conn
      |> post(Routes.user_path(conn, :update, user.id), to_update)
      |> json_response(200)

    assert Map.get(res, "id") == user.id
    assert Map.get(res, "name") == to_update["name"]
    assert Map.get(res, "email") == to_update["email"]
  end
end
