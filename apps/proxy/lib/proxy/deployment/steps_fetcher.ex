defmodule Proxy.Deployment.StepsFetcher do
  @moduledoc """
  Module will fetch list of steps from deployment service
  Fetching might be triggered by timeout (automatically) or manually
  by calling `Proxy.Deploy.StepsFetcher.fetch/0`
  """
  use GenServer
  alias Proxy.Deployment.BaseApi

  require Logger

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(_) do
    Process.send_after(__MODULE__, :load, 10)
    {:ok, nil, timeout()}
  end

  @doc false
  def handle_info(:timeout, state), do: {:noreply, state}

  @doc false
  def handle_info(:load, _state) do
    {:ok, %{"type" => "ok", "result" => details}} = BaseApi.load_steps()
    {:noreply, details, timeout()}
  end

  @doc false
  def handle_cast(:fetch, _state) do
    {:ok, %{"type" => "ok", "result" => details}} = BaseApi.load_steps()
    {:noreply, details, timeout()}
  end

  @doc false
  def handle_call(:get, state), do: {:reply, state, state}

  @doc """
  Get steps details
  """
  @spec get() :: nil | map()
  def get(), do: GenServer.call(__MODULE__, :get)

  # get deployment timeout
  defp timeout(), do: Application.get_env(:proxy, :deployment_steps_fetch_timeout, 600_000)
end
