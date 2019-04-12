defmodule WebApiWeb.DeploymentController do
  use WebApiWeb, :controller

  action_fallback WebApiWeb.FallbackController

  alias Proxy.Deployment.StepsFetcher
  alias Proxy.Deployment.BaseApi
  alias WebApiWeb.SuccessView

  def steps(conn, _) do
    case StepsFetcher.all() do
      nil ->
        conn
        |> put_status(200)
        |> put_view(SuccessView)
        |> render("200.json", data: %{})

      steps when is_map(steps) ->
        conn
        |> put_status(200)
        |> put_view(SuccessView)
        |> render("200.json", data: steps)
    end
  end

  def reload(conn, _) do
    StepsFetcher.reload()

    conn
    |> put_status(200)
    |> put_view(SuccessView)
    |> render("200.json", data: %{})
  end

  def commit_list(conn, _) do
    with {:ok, list} <- BaseApi.get_commit_list() do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: list)
    end
  end
end
