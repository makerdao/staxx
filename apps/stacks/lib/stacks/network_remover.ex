defmodule Stacks.NetworkRemover do
  @moduledoc """
  Module removes unused networks for docker env
  """
  use GenServer

  require Logger

  # @timeout 180_000
  @timeout 10_000

  @doc false
  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc false
  def init(:ok),
    do: {:ok, :ok, @timeout}

  @doc false
  def handle_info(:timeout, state) do
    Logger.debug(fn -> "Clearing unused docker netwrorks" end)
    Proxy.Chain.Docker.prune_networks()
    {:noreply, state, @timeout}
  end
end
