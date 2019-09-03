defmodule Staxx.Domains.Models.UserTest do
  use Staxx.Domains.RepoCase
  alias Staxx.Domains.Models.User

  test "should create new user" do
    {:ok, %User{id: id}} =
      :user
      |> build()
      |> User.changeset()
      |> Repo.insert()

    assert id > 0
  end

  test "same emails should not pass" do
    params = build(:user)

    {:ok, %User{}} =
      params
      |> User.changeset()
      |> Repo.insert()

    assert {:error, _} =
             params
             |> User.changeset()
             |> Repo.insert()
  end
end
