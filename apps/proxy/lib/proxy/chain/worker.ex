defmodule Proxy.Chain.Worker do
  @moduledoc """
  Chain/deployment/other tasks performer. 

  All tasksthat will iteract with chain should go through this worker.
  """

  use GenServer

  require Logger

  alias Proxy.Chain.Worker.State

  @doc false
  def start_link(id) when is_binary(id), do: GenServer.start_link(__MODULE__, %State{id: id})
  def start_link(_id), do: GenServer.start_link(__MODULE__, %State{})

  @doc false
  def init(%State{id: nil} = state), do: {:ok, state}

  def init(%State{id: id} = state) do
    Logger.debug("#{id}: Loading chain details")
    {:ok, state}
  end
end
