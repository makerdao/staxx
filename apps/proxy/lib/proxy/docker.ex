defmodule Proxy.Docker do
  @moduledoc """
  Docker service integration
  """

  alias Docker.Struct.Container
  alias Proxy.NodeManager

  # Response waiting timeout
  @timeout 30_000

  @doc """
  Start new docker image
  """
  @spec start(Container.t()) :: {:ok, Container.t()} | {:error, term}
  def start(%Container{} = container) do
    case NodeManager.docker_node() do
      nil ->
        {:error, "No docker node connected"}

      node ->
        GenServer.call({Docker.Cmd, node}, {:start, container}, @timeout)
    end
  end

  @doc """
  Stop running container
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(id) do
    case NodeManager.docker_node() do
      nil ->
        {:error, "No docker node connected"}

      node ->
        GenServer.call({Docker.Cmd, node}, {:stop, id}, @timeout)
    end
  end

  @doc """
  Prune all networks
  """
  @spec prune_networks() :: :ok | {:error, term}
  def prune_networks() do
    case NodeManager.docker_node() do
      nil ->
        {:error, "No docker node connected"}

      node ->
        GenServer.cast({Docker.Cmd, node}, :prune_networks)
    end
  end
end
