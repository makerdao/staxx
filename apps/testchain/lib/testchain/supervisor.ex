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

  alias Staxx.Testchain
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
  def start_link({id, _config_of_id} = params),
    do: Supervisor.start_link(__MODULE__, params, name: via(id))

  @impl true
  def init({id, chain_config}) when is_map(chain_config) do
    chain_config
    |> Helper.to_evm_config()
    |> EVM.child_spec()
    |> do_init(id)
  end

  @impl true
  def init({id, existing_id}) when is_binary(existing_id) do
    existing_id
    |> Helper.load_exitsing_chain_config()
    |> EVM.child_spec()
    |> do_init(id)
  end

  @doc """
  Stops supervisor with all it's shildren
  """
  @spec stop(Testchain.evm_id()) :: :ok
  def stop(id) do
    Logger.debug(fn -> "#{id}: Trying to stop Testchain supervisor tree" end)

    id
    |> via()
    |> Supervisor.stop({:shutdown, id})
  end

  # Does Supervisor initialisation
  defp do_init(evm_spec, id) do
    children = [
      evm_spec,
      {HealthChecker, id}
    ]

    opts = [strategy: :rest_for_one]
    Supervisor.init(children, opts)
  end

  defp via(id),
    # do: {:via, Registry, {EVMRegistry, "supervisor_#{id}"}}
    do: {:global, "testchain_supervisor_#{id}"}
end
