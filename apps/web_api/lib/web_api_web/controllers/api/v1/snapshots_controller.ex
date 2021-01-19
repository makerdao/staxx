defmodule Staxx.WebApiWeb.Api.V1.SnapshotController do
  use Staxx.WebApiWeb, :controller

  action_fallback Staxx.WebApiWeb.Api.V1.FallbackController

  alias Staxx.Testchain
  alias Staxx.Testchain.SnapshotManager
  alias Staxx.WebApiWeb.Api.V1.SuccessView
  alias Staxx.WebApiWeb.Api.V1.ErrorView
  alias Staxx.WebApiWeb.Schemas.TestchainSchema

  # content type of snapshot that will be uploaded
  @filetypes ["application/x-gzip", "application/gzip"]

  # Take snapshot command
  def take_snapshot(conn, %{"id" => id} = params) do
    with :ok <- Testchain.take_snapshot(id, Map.get(params, "description", "")) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{message: "Taking snapshot."})
    end
  end

  # Take snapshot command
  def revert_snapshot(conn, %{"id" => id, "snapshot_id" => snapshot_id})
      when is_binary(snapshot_id) do
    with :ok <- Testchain.revert_snapshot(id, snapshot_id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{message: "Reverting snapshot."})
    end
  end

  # load list of snapshots for chain
  def list_snapshots(conn, %{"evm_type" => evm_type}) do
    list =
      evm_type
      |> String.to_atom()
      |> SnapshotManager.by_chain()

    conn
    |> put_status(200)
    |> put_view(SuccessView)
    |> render("200.json", data: list)
  end

  def remove_snapshot(conn, %{"id" => id}) do
    with :ok <- SnapshotManager.remove(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: [])
    end
  end

  def upload_snapshot(conn, %{
        "snapshot" => %{"file" => file, "description" => description, "type" => type}
      }) do
    id =
      file
      |> Map.get(:filename)
      |> String.replace(".tgz", "")

    with true <- Map.get(file, :content_type) in @filetypes,
         true <- "" != description,
         true <- File.exists?(Map.get(file, :path)),
         :ok <- copy_snapshot(file),
         chain_type <- String.to_atom(type),
         {:ok, details} <- SnapshotManager.upload(id, chain_type, description) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: details)
    end
  end

  def upload_snapshot(conn, _params) do
    conn
    |> put_status(400)
    |> put_view(ErrorView)
    |> render("400.json", message: "Wrong details passed")
  end

  # Load snapshot details and download file
  def download_snapshot(conn, %{"id" => id}) do
    with %{path: path} <- SnapshotManager.by_id(id),
         true <- File.exists?(path) do
      conn
      |> send_download({:file, path})
    else
      _ ->
        conn
        |> put_status(404)
        |> put_view(ErrorView)
        |> render("404.json")
    end
  end

  # Generate path where to store file
  defp copy_snapshot(%Plug.Upload{path: path, filename: name}) do
    destination =
      :testchain
      |> Application.get_env(:snapshot_base_path)
      |> Path.join(name)

    case File.exists?(destination) do
      true ->
        :ok

      false ->
        File.cp(path, destination)
    end
  end
end
