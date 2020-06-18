defmodule Staxx.WebApiWeb.ChainChannel do
  @moduledoc """
  Controlling functions for specified chains
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Environment

  use Phoenix.Channel, log_join: false, log_handle_in: :debug
  # alias Chain.Snapshot.Details, as: SnapshotDetails

  # Handle someone joined chain
  def join("chain:" <> _chain_id, _, socket),
    do: {:ok, socket}

  # Stop chain
  def handle_in("stop", _, %{topic: "chain:" <> id} = socket) do
    :ok = Environment.stop(id)
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
    case Testchain.take_snapshot(id, description) do
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
    case Testchain.revert_snapshot(id, snapshot_id) do
      :ok ->
        {:reply, {:ok, %{status: "ok"}}, socket}

      {:error, err} ->
        {:reply, {:error, %{message: err}}, socket}

      err ->
        Logger.error("#{id}: Failed to revert snapshot: #{inspect(err)}")
        {:reply, {:error, %{message: "failed to revert snapshot"}}, socket}
    end
  end
end
