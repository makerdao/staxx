defmodule Staxx.DeploymentScope.Deployment.Deployer do
  @moduledoc """
  Module is responsible for deployment processes
  """

  require Logger

  alias Staxx.DeploymentScope.DeploymentRegistry
  alias Staxx.DeploymentScope.Deployment.BaseApi
  alias Staxx.DeploymentScope.Deployment.StepsFetcher
  alias Staxx.DeploymentScope.Deployment.TaskSupervisor

  @timeout Application.get_env(:deployment_scope, :action_timeout)

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
end
