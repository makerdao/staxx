defmodule Storage.InMemory do
  use GenServer

  def init(state) do
    {:ok, state}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{deployments: %{}}, name: __MODULE__)
  end

  def handle_cast({:add_deployment, params}, state) do
    state = %{state | deployments: Map.put(state.deployments, build_deployment_key_by_params(params), params)}
    {:noreply, state}
  end

  def handle_cast({:delete_deployment, params}, state) do
    state = %{state | deployments: Map.delete(state.deployments, build_deployment_key_by_params(params))}
    {:noreply, state}
  end

  defp build_deployment_key_by_params(params) do
    {"#{params.host}:#{params.port}}"}
  end

  def handle_call(:get_deployment_list, _, state) do
    {:reply, Map.keys(state.deployments), state}
  end

  def add_deployment(params) do
    GenServer.cast(__MODULE__, {:add_deployment, params})
  end

  def delete_deployment(params) do
    GenServer.cast(__MODULE__, {:delete_deployment, params})
  end

  def get_deployment_list() do
    GenServer.call(__MODULE__, :get_deployment_list)
  end

end
