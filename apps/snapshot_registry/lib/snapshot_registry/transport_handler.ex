defmodule Staxx.SnapshotRegistry.TransportHandler do
  @moduledoc """
  Module for handling transport messages
  """

  use GenServer

  require Logger

  alias Staxx.SnapshotRegistry.Models.Snapshot

  @doc false
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(default),
    do: GenServer.start_link(__MODULE__, default)

  @doc """
  Initializing transport server to receive messages from it
  When transport server finish download, this module receive :transfer_complete message
  When transport server fail download, this module receive :transfer_failed message
  """
  @impl true
  @spec init(map()) :: {:ok, map()}
  def init(state) do
    Logger.info("Initializing TransportHandler with #{inspect(self())} pid")

    {:ok, _pid} =
      Staxx.Transport.Server.start_link(%{
        receiver_pid: self(),
        tmp_dir: build_temporary_path(),
        transport_port: Application.get_env(:snapshot_registry, :socket_port)
      })

    {:ok, state}
  end

  @doc """
  Receiving and verification authorization token.
  """
  @impl true
  def handle_call({:tcp_server, {:auth, token}}, _from, state) do
    Logger.info("Check authorization token #{inspect(token)}")

    {:reply, true, state}
  end

  @doc """
  Receiving transfer completed event
  Move temporary file to base snapshots directory and create record in DB with description information
  """
  @impl true
  def handle_info(
        {:tcp_server,
         {:transfer_complete, _token,
          %{filepath: filepath, payload: %{chain_type: chain_type, description: description}} =
            data}},
        state
      ) do
    Logger.info("Handle transfer_complete start with data: #{inspect(data)}")

    # generate snapshot id
    <<new_unique_id::big-integer-size(8)-unit(8)>> = :crypto.strong_rand_bytes(8)
    unique_id = to_string(new_unique_id)

    # move temporary file to base path
    case File.rename(filepath, build_base_path(unique_id)) do
      :ok ->
        Snapshot.create(%{
          id: unique_id,
          description: description,
          chain_type: chain_type
        })

      _ ->
        Logger.error("Rename file error #{filepath}")
    end

    {:noreply, state}
  end

  @doc """
  Receiving transfer failed event.
  """
  @impl true
  def handle_info({:tcp_server, {:transfer_failed, _token, reason}}, state) do
    Logger.error("Handle transfer failed with reason: #{inspect(reason)}")

    {:noreply, state}
  end

  # Build temporary path for snapshots
  defp build_temporary_path() do
    :snapshot_registry
    |> Application.get_env(:snapshot_temporary_path)
    |> Path.expand()
  end

  # Build base path for snapshots
  defp build_base_path(filename) do
    :snapshot_registry
    |> Application.get_env(:snapshot_base_path)
    |> Path.expand()
    |> Path.join(filename)
  end
end
