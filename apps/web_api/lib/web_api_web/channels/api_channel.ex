defmodule WebApiWeb.ApiChannel do
  @moduledoc """
  Default channel for API manipulation
  """

  use Phoenix.Channel, log_join: false, log_handle_in: :debug

  require Logger

  alias WebApi.ChainMessageHandler
  alias Proxy.ExChain

  def join(_, _, socket), do: {:ok, %{message: "Welcome to ExTestchain !"}, socket}

  @doc """
  Start existing chain
  """
  def handle_in("start_existing", %{"id" => id}, socket) do
    case Proxy.start(id, ChainMessageHandler) do
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
    config = %{
      type: String.to_atom(Map.get(payload, "type", "ganache")),
      # id: Map.get(payload, "id"),
      # http_port: Map.get(payload, "http_port"),
      # ws_port: Map.get(payload, "ws_port"),
      # db_path: Map.get(payload, "db_path", ""),
      network_id: Map.get(payload, "network_id", 999),
      accounts: Map.get(payload, "accounts", 1),
      block_mine_time: Map.get(payload, "block_mine_time", 0),
      clean_on_stop: Map.get(payload, "clean_on_stop", false),
      description: Map.get(payload, "description", ""),
      snapshot_id: Map.get(payload, "snapshot_id"),
      step_id: Map.get(payload, "step_id", 0)
    }

    case Proxy.start(config, ChainMessageHandler) do
      {:ok, id} ->
        # Subscribing to notification :started and sending response to socket
        # ChainMessageHandler.notify_on(id, :started, self(), socket_ref(socket))
        {:reply, {:ok, %{id: id}}, socket}

      {:error, err} ->
        {:reply, {:error, %{message: err}}, socket}
    end
  end

  @doc """
  Get list of snapshots for given chain type
  """
  def handle_in("list_snapshots", %{"chain" => chain}, socket) do
    with list when is_list(list) <- chain |> String.to_atom() |> ExChain.snapshot_list(),
         list <- Enum.map(list, &Map.from_struct/1) do
      {:reply, {:ok, %{snapshots: list}}, socket}
    else
      _ ->
        {:reply, {:error, %{message: "Failed to load list of snapshots"}}, socket}
    end
  end

  def handle_in("list_chains", _, socket) do
    case ExChain.chain_list() do
      list when is_list(list) ->
        {:reply, {:ok, %{chains: list}}, socket}

      err ->
        Logger.error("Error retreiving list of chains #{inspect(err)}")
        {:reply, {:error, %{message: "Failed to load list of chains"}}, socket}
    end
  end

  def handle_in("remove_chain", %{"id" => id}, socket) do
    with :ok <- ExChain.clean(id),
         _ <- Proxy.Chain.Storage.delete(id) do
      {:reply, {:ok, %{message: "Chain removed"}}, socket}
    else
      _ ->
        {:reply, {:error, %{message: "Something wrong on removing chain"}}, socket}
    end
  end
end
