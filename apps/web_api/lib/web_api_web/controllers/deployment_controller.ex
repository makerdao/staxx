defmodule WebApiWeb.DeploymentController do
  use WebApiWeb, :controller

  action_fallback WebApiWeb.FallbackController

  alias Proxy.Deployment.StepsFetcher
  alias WebApiWeb.SuccessView

  def steps(conn, _) do
    case StepsFetcher.get() do
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
end
