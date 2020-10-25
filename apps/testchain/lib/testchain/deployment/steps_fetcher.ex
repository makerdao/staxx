defmodule Staxx.Testchain.Deployment.StepsFetcher do
  @moduledoc """
  Module will fetch list of steps from deployment service
  Fetching might be triggered by timeout (automatically) or manually
  by calling `Staxx.Testchain.Deploy.StepsFetcher.reload/0`
  """
  use GenServer
  alias Staxx.Testchain.Deployment.BaseApi

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
        # Logger.debug("Loaded steps from deployment service")
        {:noreply, details, timeout()}

      _ ->
        {:noreply, state, timeout()}
    end
  end

  @doc false
  def handle_call({:get, step_id}, _from, %{"steps" => steps} = state) do
    step =
      steps
      |> Enum.find(fn %{"id" => id} -> id == step_id end)

    {:reply, step, state}
  end

  @doc false
  def handle_call({:get, _step_id}, _from, state),
    do: {:reply, nil, state}

  @doc false
  def handle_call(:hash, _from, %{"tagHash" => hash} = state),
    do: {:reply, hash, state}

  @doc false
  def handle_call(:hash, _from, state),
    do: {:reply, nil, state}

  @doc false
  def handle_call(:all, _from, state),
    do: {:reply, state, state}

  @doc """
  Get steps details
  """
  @spec all() :: nil | map()
  def all(), do: GenServer.call(__MODULE__, :all)

  @doc """
  Reload list of steps from deplyment service
  """
  @spec reload() :: :ok
  def reload(), do: send(__MODULE__, :load)

  @doc """
  Get step details
  """
  @spec get(1..9) :: nil | map()
  def get(step_id),
    do: GenServer.call(__MODULE__, {:get, step_id})

  @doc """
  Get hash from git commit
  """
  @spec hash() :: nil | binary
  def hash(),
    do: GenServer.call(__MODULE__, :hash)

  # get deployment timeout
  defp timeout(),
    do: Application.get_env(:instance, :deployment_steps_fetch_timeout, 600_000)
end
