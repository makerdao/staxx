defmodule WebApiWeb.StackController do
  use WebApiWeb, :controller

  require Logger

  action_fallback WebApiWeb.FallbackController

  alias WebApiWeb.SuccessView
  alias WebApiWeb.ErrorView

  alias WebApi.ChainMessageHandler
  alias WebApi.Utils

  # Start new stack
  def start(conn, %{"testchain" => %{"config" => chain_config}} = params) do
    Logger.debug("#{__MODULE__}: New stack is starting")
    IO.inspect(params)
    config = Utils.chain_config_from_payload(chain_config)

    with {:ok, id} <- Stacks.start(config, params, ChainMessageHandler) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{id: id})
    end
  end

  # Stop stack
  def stop(conn, %{"id" => id}) do
    Logger.debug("#{__MODULE__}: Stopping stack #{id}")

    with :ok <- Stacks.stop(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{})
    end
  end
end
