defmodule Staxx.WebApiWeb.ChainController do
  use Staxx.WebApiWeb, :controller

  action_fallback Staxx.WebApiWeb.FallbackController

  alias Staxx.Testchain
  alias Staxx.Testchain.SnapshotManager
  alias Staxx.Store.Models.Chain, as: ChainRecord
  alias Staxx.Store.Models.User, as: UserRecord
  alias Staxx.WebApiWeb.SuccessView
  alias Staxx.WebApiWeb.ErrorView

  # content type of snapshot that will be uploaded
  @filetype "application/gzip"

  # Get version for binaries and chain
  def version(conn, _) do
    with version when is_binary(version) <- Testchain.version() do
      conn
      |> text(version)
    end
  end

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
  def revert_snapshot(conn, %{"id" => id, "snapshot" => snapshot_id})
      when is_binary(snapshot_id) do
    with :ok <- Testchain.revert_snapshot(id, snapshot_id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{message: "Reverting snapshot."})
    end
  end

  def list_chains(conn, _) do
    list =
      conn
      |> get_user_email()
      |> UserRecord.get_user_id()
      |> ChainRecord.list()

    conn
    |> put_status(200)
    |> put_view(SuccessView)
    |> render("200.json", data: list)
  end

  # Load chain details for running chain
  def chain_details(conn, %{"id" => id}) do
    with info when is_map(info) <- ChainRecord.get(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: info)
    else
      nil ->
        conn
        |> put_status(404)
        |> put_view(ErrorView)
        |> render("404.json")
    end
  end

  # Remove chain details from internal storage
  def remove_chain(conn, %{"id" => id}) do
    with :ok <- Testchain.remove(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: %{message: "Chain data will be deleted"})
    else
      {:error, msg} ->
        conn
        |> put_status(400)
        |> put_view(ErrorView)
        |> render("400.json", message: msg)
    end
  end

  # load list of snapshots for chain
  def list_snapshots(conn, %{"chain" => chain}) do
    list =
      chain
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

    with @filetype <- Map.get(file, :content_type),
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
