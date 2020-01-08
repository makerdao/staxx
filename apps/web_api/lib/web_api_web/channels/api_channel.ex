defmodule Staxx.WebApiWeb.ApiChannel do
  @moduledoc """
  Default channel for API manipulation
  """

  use Phoenix.Channel, log_join: false, log_handle_in: :debug

  require Logger

  alias Staxx.Testchain
  alias Staxx.DeploymentScope
  alias Staxx.Testchain.SnapshotManager
  alias Staxx.Store.Models.Chain, as: ChainRecord

  def join(_, _, socket), do: {:ok, %{message: "Welcome to ExTestchain !"}, socket}

  @doc """
  Start existing chain
  """
  def handle_in("start_existing", payload, socket) do
    with {:ok, id} <- DeploymentScope.start(payload) do
      {:reply, {:ok, %{id: id}}, socket}
    else
      {:error, err} ->
        {:reply, {:error, %{message: err}}, socket}
    end
  end

  @doc """
  Start new chain handler
  """
  def handle_in("start", payload, socket) do
    with {:ok, id} <- DeploymentScope.start(payload) do
      {:reply, {:ok, %{id: id}}, socket}
    else
      {:error, err} ->
        {:reply, {:error, %{message: err}}, socket}
    end
  end

  @doc """
  Get list of snapshots for given chain type
  """
  def handle_in("list_snapshots", %{"chain" => chain}, socket) do
    list =
      chain
      |> String.to_atom()
      |> SnapshotManager.by_chain()

    {:reply, {:ok, %{snapshots: list}}, socket}
  end

  def handle_in("list_chains", _, socket) do
    case ChainRecord.list() do
      list when is_list(list) ->
        {:reply, {:ok, %{chains: list}}, socket}

      err ->
        Logger.error("Error retreiving list of chains #{inspect(err)}")
        {:reply, {:error, %{message: "Failed to load list of chains"}}, socket}
    end
  end

  def handle_in("remove_chain", %{"id" => id}, socket) do
    with :ok <- Testchain.remove(id) do
      {:reply, {:ok, %{message: "Chain removed"}}, socket}
    else
      _ ->
        {:reply, {:error, %{message: "Something wrong on removing chain"}}, socket}
    end
  end
end
