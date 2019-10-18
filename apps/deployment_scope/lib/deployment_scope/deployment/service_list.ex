defmodule Staxx.DeploymentScope.Deployment.ServiceList do
  @moduledoc """
  Module that will register deployment service connectivity.
  On connection it should force steps update etc. for Proxy app
  """
  use GenServer
  require Logger

  alias Staxx.DeploymentScope.Deployment.StepsFetcher

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{deployments: %{}}, name: __MODULE__)
  end

  @doc false
  def init(state) do
    {:ok, state}
  end

  @doc false
  def handle_cast({:add_deployment, params}, %{deployments: deployments} = state) do
    updated =
      deployments
      |> Map.put(build_deployment_key_by_params(params), params)

    Logger.debug('Deployemnt service connected. Triggering fetch steps')
    StepsFetcher.reload()
    {:noreply, %{state | deployments: updated}}
  end

  @doc false
  def handle_cast({:delete_deployment, params}, %{deployments: deployments} = state) do
    updated =
      deployments
      |> Map.delete(build_deployment_key_by_params(params))

    {:noreply, %{state | deployments: updated}}
  end

  @doc false
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

  defp build_deployment_key_by_params(%{host: host, port: port}),
    do: "#{host}:#{port}"
end
