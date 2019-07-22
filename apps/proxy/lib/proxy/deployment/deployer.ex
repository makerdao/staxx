defmodule Staxx.Proxy.Deployment.Deployer do
  @moduledoc """
  Module is responsible for deployment processes
  """

  require Logger

  alias Staxx.Proxy.DeploymentRegistry
  alias Staxx.Proxy.Deployment.BaseApi
  alias Staxx.Proxy.Deployment.StepsFetcher
  alias Staxx.Proxy.Deployment.TaskSupervisor

  @timeout Application.get_env(:proxy, :action_timeout)

  @spec deploy(binary, 1..9, binary, binary, binary) :: :ok | {:error, term}
  def deploy(chain_id, step_id, rpc_url, coinbase, commit \\ nil) do
    with {:checkout, :ok} <- {:checkout, checkout(commit)},
         {:ok, request_id} <- run_deployment(chain_id, step_id, rpc_url, coinbase) do
      {:ok, request_id}
    end
  end

  @doc """
  Handle deployment service notifications from NATs or HTTP layer.
  """
  @spec handle(binary, term) :: :ok
  def handle(request_id, data) do
    Registry.dispatch(DeploymentRegistry, request_id, fn entries ->
      for {pid, _} <- entries, do: send(pid, data)
    end)
  end

  @doc """
  Checkout deployment service to given commit/tag
  """
  @spec checkout(nil | binary) :: :ok | {:error, term}
  def checkout(nil), do: :ok

  def checkout(commit) do
    req_id = BaseApi.random_id()

    TaskSupervisor
    |> Task.Supervisor.async(fn ->
      {:ok, _} = Registry.register(DeploymentRegistry, req_id, [])
      {:ok, _} = BaseApi.checkout(req_id, commit)

      receive do
        {:checkout, data} ->
          Logger.debug("Got result for #{req_id} and system checked out to: #{inspect(data)}")

          StepsFetcher.reload()
          :ok
      after
        @timeout ->
          {:error, :checkout_timeout}
      end
    end)
    |> Task.await(@timeout)
  end

  # TODO: May be use that
  defp run_deploy(id, step_id, rpc_url, coinbase) do
    request_id = BaseApi.random_id()
    Logger.debug("#{id}: Starting deployment process with id: #{request_id}")

    env = %{
      "ETH_RPC_URL" => rpc_url,
      "ETH_FROM" => coinbase,
      "ETH_RPC_ACCOUNTS" => "yes",
      "SETH_STATUS" => "yes"
      # "ETH_GAS" => Map.get(details, :gas_limit),
      # "ETH_GAS" => "6000000"
    }

    TaskSupervisor
    |> Task.Supervisor.async(fn ->
      {:ok, _} = Registry.register(DeploymentRegistry, request_id, [])
      {:ok, _} = BaseApi.run(request_id, step_id, env)

      # receive do
      # {:deployment, data} ->
      # end
    end)
    |> Task.await(@timeout)
  end

  defp run_deployment(id, step_id, rpc_url, coinbase) do
    request_id = BaseApi.random_id()
    Logger.debug("#{id}: Starting deployment process with id: #{request_id}")

    env = %{
      "ETH_RPC_URL" => String.replace(rpc_url, "localhost", "host.docker.internal"),
      "ETH_FROM" => coinbase,
      "ETH_RPC_ACCOUNTS" => "yes",
      "SETH_STATUS" => "yes",
      # "ETH_GAS" => Map.get(details, :gas_limit),
      "ETH_GAS" => "19000000"
    }

    case BaseApi.run(request_id, step_id, env) do
      {:ok, %{"type" => "ok"}} ->
        {:ok, request_id}

      _ ->
        {:error, "failed to start deployment"}
    end
  end
end
