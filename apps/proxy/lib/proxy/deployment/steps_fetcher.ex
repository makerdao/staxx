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
  def handle_info(:timeout, state) do
    Process.send_after(__MODULE__, :load, 10)
    {:noreply, state}
  end

  @doc false
  def handle_info(:load, state) do
    case BaseApi.load_steps() do
      {:ok, %{"type" => "ok", "result" => details}} ->
        Logger.debug("Loaded steps from deployment service")
        {:noreply, details, timeout()}

      _ ->
        {:noreply, state, timeout()}
    end
  end

  @doc false
  def handle_cast(:fetch, _state) do
    {:ok, %{"type" => "ok", "result" => details}} = BaseApi.load_steps()
    {:noreply, details, timeout()}
  end

  @doc false
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @doc """
  Get steps details
  """
  @spec get() :: nil | map()
  def get(), do: GenServer.call(__MODULE__, :get)

  @doc """
  Reload list of steps from deplyment service
  """
  @spec reload() :: :ok
  def reload(), do: send(__MODULE__, :load)

  # get deployment timeout
  defp timeout(), do: Application.get_env(:proxy, :deployment_steps_fetch_timeout, 600_000)
end
