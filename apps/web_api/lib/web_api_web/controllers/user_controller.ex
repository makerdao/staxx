defmodule Staxx.WebApiWeb.UserController do
  use Staxx.WebApiWeb, :controller

  require Logger
  alias Staxx.Store.Models.User

  alias Staxx.WebApiWeb.SuccessView
  action_fallback Staxx.WebApiWeb.FallbackController

  @doc """
  List of all users in system
  """
  def list(conn, params) do
    with users <- User.list(Map.get(params, "limit", 50), Map.get(params, "offset", 0)) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: users)
    end
  end

  @doc """
  Create new user in system
  """
  def create(conn, params) do
    with {:ok, user} <- User.create(params) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: user)
    end
  end

  @doc """
  Update given user
  """
  def update(conn, %{"id" => user_id} = params) do
    with %User{} = user <- User.get(user_id),
         {:ok, updated} <- User.update(user, params) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: updated)
    end
  end

  @doc """
  Get user details
  """
  def get(conn, %{"id" => user_id}) do
    with %User{} = user <- User.get(user_id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: user)
    end
  end
end
