defmodule WebApiWeb.ChainController do
  use WebApiWeb, :controller

  action_fallback WebApiWeb.FallbackController

  alias Proxy.ExChain

  alias WebApiWeb.SuccessView
  # alias Chain.SnapshotManager

  # Get version for binaries and chain
  def version(conn, _) do
    with version when is_binary(version) <- ExChain.version() do
      conn
      |> text(version)
    end
  end

  def chain_list(conn, _) do
    with list when is_list(list) <- Proxy.chain_list() do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: list)
    end
  end

  # load list of snapshots for chain
  def snapshot_list(conn, %{"chain" => chain}) do
    with list when is_list(list) <- chain |> String.to_atom() |> ExChain.snapshot_list(),
         list <- Enum.map(list, &Map.from_struct/1) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: list)
    end
  end

  # Load snapshot detailt and download file
  def download_snapshot(conn, %{"id" => id}) do
    with %{path: path} <- ExChain.get_snapshot(id),
         true <- File.exists?(path) do
      conn
      |> send_download({:file, path})
    else
      _ ->
        conn
        |> put_status(404)
        |> put_view(WebApiWeb.ErrorView)
        |> render("404.json")
    end
  end

  # Remove chain details from internal storage
  def remove_chain(conn, %{"id" => id}) do
    with :ok <- Proxy.clean(id) do
      conn
      |> put_status(200)
      |> json(%{status: 0, message: "Chain data will be deleted"})
    end
  end

  # Load chain details for running chain
  def details(conn, %{"id" => id}) do
    with info when is_map(info) <- Proxy.details(id) do
      conn
      |> json(%{status: 0, details: info})
    end
  end
end
