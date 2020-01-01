defmodule Staxx.Testchain.Supervisor do
  @moduledoc """
  Deployment scope supervisor.
  It controll specific scope for user.

  Part of is will be:
   - chain - Exact EVM that will be started for scope
   - list of stacks - set of stack workers that control different stacks
  """
  use Supervisor

  require Logger

  alias Staxx.Testchain.Helper
  alias Staxx.Testchain.HealthChecker
  alias Staxx.Testchain.EVM

  @doc false
  def child_spec({id, _} = params) do
    %{
      id: "testchain_supervisor_#{id}",
      start: {__MODULE__, :start_link, [params]},
      restart: :temporary,
      type: :supervisor
    }
  end

  @doc """
  Starts new supervision tree for testchain (EVM + deployment + helpers)
  """
  def start_link({_id, _config_of_id} = params),
    do: Supervisor.start_link(__MODULE__, params)

  @impl true
  def init({id, chain_config}) when is_map(chain_config) do
    evm_spec =
      chain_config
      |> Helper.to_evm_config()
      |> EVM.child_spec()

    children = [
      evm_spec,
      {HealthChecker, id}
    ]

    opts = [strategy: :one_for_all, max_restarts: 0]
    Supervisor.init(children, opts)
  end
end
