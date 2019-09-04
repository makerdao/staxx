defmodule Staxx.WebApiWeb.ChainController do
  use Staxx.WebApiWeb, :controller

  action_fallback Staxx.WebApiWeb.FallbackController

  alias Staxx.Proxy
  alias Staxx.DeploymentScope.UserScope
  alias Staxx.WebApiWeb.SuccessView
  alias Staxx.WebApiWeb.ErrorView
  # alias Chain.SnapshotManager

  # content type of snapshot that will be uploaded
  @filetype "application/gzip"

  # Get version for binaries and chain
  def version(conn, _) do
    with version when is_binary(version) <- Proxy.version() do
      conn
      |> text(version)
    end
  end

  def upload(conn, %{
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
         {:ok, details} <- Proxy.upload_snapshot(id, chain_type, description) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: details)
    end
  end

  def upload(conn, _params) do
    conn
    |> put_status(400)
    |> put_view(ErrorView)
    |> render("400.json", message: "Wrong details passed")
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
    list =
      chain
      |> String.to_atom()
      |> Proxy.snapshot_list()

    conn
    |> put_status(200)
    |> put_view(SuccessView)
    |> render("200.json", data: list)
  end

  # Load snapshot details and download file
  def download_snapshot(conn, %{"id" => id}) do
    with %{path: path} <- Proxy.get_snapshot(id),
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

  def remove_snapshot(conn, %{"id" => id}) do
    with :ok <- Proxy.remove_snapshot(id) do
      conn
      |> put_status(200)
      |> put_view(SuccessView)
      |> render("200.json", data: [])
    end
  end

  # Remove chain details from internal storage
  def remove_chain(conn, %{"id" => id}) do
    with :ok <- Proxy.clean(id) do
      UserScope.unmap(id)

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
    else
      nil ->
        conn
        |> json(%{status: 0, details: nil, message: "Chain was not found"})

      _ ->
        conn
        |> json(%{status: 1, details: nil, message: "Error fetchign chain details"})
    end
  end

  def stop(conn, %{"id" => id}) do
    Proxy.stop(id)

    conn
    |> json(%{status: 0, details: %{}})
  end

  # Generate path where to store file
  defp copy_snapshot(%Plug.Upload{path: path, filename: name}) do
    destination =
      :proxy
      |> Application.get_env(:snapshot_path)
      |> Path.join(name)

    case File.exists?(destination) do
      true ->
        :ok

      false ->
        File.cp(path, destination)
    end
  end
end
