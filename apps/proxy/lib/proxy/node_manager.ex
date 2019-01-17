defmodule Proxy.NodeManager do
  @moduledoc """
  Node connection manager. 
  It handles new nodes connecting/disconnedting and selects right node to make a call to
  """

  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    defstruct chains: []
  end

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc false
  def init(_) do
    Logger.debug("#{__MODULE__} started")
    # Starting handling node connect/disconnect 
    :net_kernel.monitor_nodes(true)

    # Have to check list of connected nodes. 
    # because node might connect on start of application
    # and before `:net_kernel.monitor_nodes(true)` will set monitoring
    case Node.list() do
      [] ->
        {:ok, %State{}}

      list when is_list(list) ->
        Logger.debug("Connected to nodes #{inspect(list)}")
        {:ok, %State{chains: list}}
    end
  end

  @doc false
  def handle_info({:nodeup, node}, %State{chains: list} = state) do
    Logger.debug("New node connected #{node}")

    chains =
      case Enum.member?(list, node) do
        true ->
          list

        false ->
          list ++ [node]
      end

    {:noreply, %State{state | chains: chains}}
  end

  @doc false
  def handle_info({:nodedown, node}, %State{chains: list} = state) do
    Logger.debug("Node disconnected #{node}")
    {:noreply, %State{state | chains: List.delete(list, node)}}
  end

  @doc false
  def handle_call(:chain, _from, %State{chains: list} = state) do
    case list do
      [] ->
        {:reply, nil, state}

      list ->
        {:reply, Enum.random(list), state}
    end
  end

  @doc """
  Get chain node address
  """
  @spec chain() :: nil | node()
  def chain(), do: GenServer.call(__MODULE__, :chain)
end
