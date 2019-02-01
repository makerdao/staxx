defmodule Proxy.Deployment.ProcessWatcher do
  @moduledoc """
  This is special process that will store deployment requestId with chainId
  Sort of simple key => value storage.
  """
  use GenServer

  @doc false
  def start_link(_),
    do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc false
  def init(_),
    do: {:ok, %{}}

  @doc false
  def handle_cast({:add, request_id, chain_id}, state),
    do: {:noreply, Map.put(state, request_id, chain_id)}

  @doc false
  def handle_call({:pop, request_id}, _from, state) do
    {chain_id, rest} = Map.pop(state, request_id)
    {:reply, chain_id, rest}
  end

  @doc """
  Add new pair request_id -> chain_id
  """
  @spec put(binary, binary) :: :ok
  def put(request_id, chain_id), do: GenServer.cast(__MODULE__, {:add, request_id, chain_id})

  @doc """
  Pops chain_id by request_id. 
  If no such request_id exist - `nil` will be returned
  """
  @spec pop(binary) :: nil | binary | {:error, term()}
  def pop(request_id), do: GenServer.call(__MODULE__, {:pop, request_id})
end
