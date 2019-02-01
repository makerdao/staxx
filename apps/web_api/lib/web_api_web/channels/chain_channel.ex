defmodule WebApiWeb.ChainChannel do
  @moduledoc """
  Controlling functions for specified chains
  """

  require Logger

  alias Proxy.ExChain
  alias Proxy.Chain.Worker

  use Phoenix.Channel, log_join: false, log_handle_in: :debug
  # alias Chain.Snapshot.Details, as: SnapshotDetails

  # Handle someone joined chain
  def join("chain:" <> _chain_id, _, socket),
    do: {:ok, socket}

  # Stop chain
  def handle_in("stop", _, %{topic: "chain:" <> id} = socket) do
    :ok = Proxy.stop(id)
    {:reply, :ok, socket}
  end

  # Take snapshot for chain
  def handle_in(
        "take_snapshot",
        nil,
        socket
      ),
      do: handle_in("take_snapshot", %{"description" => ""}, socket)

  def handle_in(
        "take_snapshot",
        %{"description" => description},
        %{topic: "chain:" <> id} = socket
      ) do
    case ExChain.take_snapshot(id, description) do
      :ok ->
        {:reply, {:ok, %{status: "ok"}}, socket}

      {:error, err} ->
        {:reply, {:error, %{message: err}}, socket}
    end
  end

  # Revert snapshot for chain
  def handle_in(
        "revert_snapshot",
        %{"snapshot" => snapshot_id},
        %{topic: "chain:" <> id} = socket
      ) do
    with snapshot when is_map(snapshot) <- ExChain.load_snapshot(snapshot_id),
         :ok <- ExChain.revert_snapshot(id, snapshot) do
      {:reply, {:ok, %{status: "ok"}}, socket}
    else
      err ->
        Logger.error("#{id}: Failed to revert snapshot: #{inspect(err)}")
        {:reply, {:error, %{message: "failed to revert snapshot"}}, socket}
    end
  end

  # Run deployment
  def handle_in("deploy", %{"step" => step}, %{topic: "chain:" <> id} = socket) do
    res =
      id
      |> Worker.get_pid()
      |> GenServer.call({:deploy, step})

    case res do
      :ok ->
        {:reply, {:ok, %{status: "ok"}}, socket}

      {:error, err} ->
        {:reply, {:error, %{message: err}}, socket}
    end
  end
end
