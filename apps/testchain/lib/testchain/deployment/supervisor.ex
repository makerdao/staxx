defmodule Staxx.Testchain.Deployment.Supervisor do
  @moduledoc """
  Main supervisor
  """
  use Supervisor, restart: :transient

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Staxx.Testchain.Deployment.StepsFetcher,
      {Registry, keys: :unique, name: Staxx.Testchain.DeploymentRegistry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
