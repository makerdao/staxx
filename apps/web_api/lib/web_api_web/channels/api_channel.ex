defmodule Staxx.WebApiWeb.ApiChannel do
  @moduledoc """
  Default channel for API manipulation
  """

  use Phoenix.Channel, log_join: false, log_handle_in: :debug

  require Logger

  alias Staxx.Proxy
  alias Staxx.DeploymentScope.EVMWorker.Storage
  alias Staxx.DeploymentScope.EVMWorker.ChainHelper

  def join(_, _, socket), do: {:ok, %{message: "Welcome to ExTestchain !"}, socket}

  @doc """
  Start existing chain
  """
  def handle_in("start_existing", %{"id" => id}, socket) do
    Logger.error(fn -> "Removed totally. Need to rework !" end)

    case Proxy.start(id) do
      {:ok, id} ->
        {:reply, {:ok, %{id: id}}, socket}

      {:error, err} ->
        {:reply, {:error, %{message: err}}, socket}
    end
  end

  @doc """
  Start new chain handler
  """
  def handle_in("start", payload, socket) do
    config = ChainHelper.config_from_payload(payload)

    Logger.error(fn -> "Removed totally. Need to rework !" end)

    case Proxy.start(config) do
      {:ok, id} ->
        {:reply, {:ok, %{id: id}}, socket}

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
      |> Proxy.snapshot_list()

    {:reply, {:ok, %{snapshots: list}}, socket}
  end

  def handle_in("list_chains", _, socket) do
    case Proxy.chain_list() do
      list when is_list(list) ->
        {:reply, {:ok, %{chains: list}}, socket}

      err ->
        Logger.error("Error retreiving list of chains #{inspect(err)}")
        {:reply, {:error, %{message: "Failed to load list of chains"}}, socket}
    end
  end

  def handle_in("remove_chain", %{"id" => id}, socket) do
    with :ok <- Proxy.clean(id),
         _ <- Storage.delete(id) do
      {:reply, {:ok, %{message: "Chain removed"}}, socket}
    else
      _ ->
        {:reply, {:error, %{message: "Something wrong on removing chain"}}, socket}
    end
  end
end
