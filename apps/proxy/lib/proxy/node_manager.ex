defmodule Proxy.NodeManager do
  @moduledoc """
  Node connection manager. 
  It handles new nodes connecting/disconnedting and selects right node to make a call to
  """

  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    defstruct dockers: [], chains: []
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
        chain_nodes =
          list
          |> Enum.filter(&is_chain_node/1)

        docker_nodes =
          list
          |> Enum.filter(&is_docker_node/1)

        Logger.debug("Connected to chain nodes #{inspect(chain_nodes)}")
        Logger.debug("Connected to docker nodes #{inspect(docker_nodes)}")

        {:ok, %State{chains: chain_nodes, dockers: docker_nodes}}
    end
  end

  @doc false
  def handle_info({:nodeup, node}, %State{} = state) do
    Logger.debug("New node connected #{node}")

    new_state =
      state
      |> add_chain_node(node)
      |> add_docker_node(node)

    {:noreply, new_state}
  end

  @doc false
  def handle_info({:nodedown, node}, %State{chains: chains, dockers: dockers} = state) do
    Logger.debug("Node disconnected #{node}")

    {:noreply,
     %State{state | chains: remove_node(chains, node), dockers: remove_node(dockers, node)}}
  end

  @doc false
  def handle_call(:node, _from, %State{chains: list} = state) do
    case list do
      [] ->
        {:reply, nil, state}

      list ->
        {:reply, Enum.random(list), state}
    end
  end

  @doc false
  def handle_call(:docker_node, _from, %State{dockers: list} = state) do
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
  @spec node() :: nil | node()
  def node(), do: GenServer.call(__MODULE__, :node)

  @doc """
  Get docker node
  """
  @spec docker_node() :: nil | node()
  def docker_node(), do: GenServer.call(__MODULE__, :docker_node)

  # Checks if this is chain node
  defp is_chain_node(node) do
    node
    |> Atom.to_string()
    |> String.contains?("chain")
  end

  # Checks if this is chain node
  defp is_docker_node(node) do
    node
    |> Atom.to_string()
    |> String.contains?("docker")
  end

  # Check if node already exist in list. 
  # Otherwise it will add it
  defp add_node(list, node) do
    case Enum.member?(list, node) do
      true ->
        list

      false ->
        list ++ [node]
    end
  end

  # Remove node from list
  defp remove_node(list, node), do: List.delete(list, node)

  # Add new chain node into list of nodes and return state
  defp add_chain_node(%State{chains: list} = state, node) do
    case is_chain_node(node) do
      false ->
        state

      true ->
        %State{state | chains: add_node(list, node)}
    end
  end

  # Add new docker node into list of nodes and return state
  defp add_docker_node(%State{dockers: list} = state, node) do
    case is_docker_node(node) do
      false ->
        state

      true ->
        %State{state | dockers: add_node(list, node)}
    end
  end
end
