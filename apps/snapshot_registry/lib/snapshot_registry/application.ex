defmodule Staxx.SnapshotRegistry.Application do
  @moduledoc false

  use Application

  require Logger

  alias Staxx.Utils

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    check_snapshot_requirements()

    children = [
      Staxx.SnapshotRegistry.Repo,
      Staxx.SnapshotRegistry.TransportHandler,
      {
        Plug.Cowboy,
        scheme: :http, plug: Staxx.SnapshotRegistry.Router, options: [port: cowboy_port()]
      }
    ]

    opts = [strategy: :one_for_one, name: Staxx.SnapshotRegistry.Supervisor]

    Logger.info("Starting SnapshotRegistry...")

    Supervisor.start_link(children, opts)
  end

  defp cowboy_port,
    do: Application.get_env(:snapshot_registry, :port, 8080)

  # Check existence of a folder for snapshots
  defp check_snapshot_requirements() do
    path =
      :snapshot_registry
      |> Application.get_env(:snapshot_base_path)
      |> Path.expand()

    unless File.dir?(path) do
      :ok = Utils.mkdir_p(path)
    end

    temporary_path =
      :snapshot_registry
      |> Application.get_env(:snapshot_temporary_path)
      |> Path.expand()

    unless File.dir?(temporary_path) do
      :ok = Utils.mkdir_p(temporary_path)
    end
  end
end
