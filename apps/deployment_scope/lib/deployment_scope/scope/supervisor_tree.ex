defmodule DeploymentScope.Scope.SupervisorTree do
  @moduledoc """
  Deployment scope supervisor.
  It controll specific scope for user.

  Part of is will be:
   - chain - Exact EVM that will be started for scope
   - list of stacks - set of stack workers that control different stacks
  """
  use Supervisor

  require Logger

  @doc false
  def child_spec(params) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [params]},
      restart: :temporary,
      type: :supervisor
    }
  end

  @doc """
  Start new supervision tree for newly created deployment scope
  """
  def start_link({id, _chain_config_or_id, _stacks} = params) do
    Supervisor.start_link(__MODULE__, params, name: via_tuple(id))
  end

  @impl true
  def init({_id, chain_config_or_id, stacks}) do
    children =
      [
        chain_child_spec(chain_config_or_id)
      ] ++ stack_workers(stacks)

    opts = [strategy: :one_for_all, max_restarts: 0]
    Supervisor.init(children, opts)
  end

  @doc """
  Generate naming via tuple for supervisor
  """
  @spec via_tuple(binary) :: {:via, Registry, {DeploymentScope.ScopeRegistry, binary}}
  def via_tuple(id),
    do: {:via, Registry, {DeploymentScope.ScopeRegistry, id}}

  defp chain_child_spec(id) when is_binary(id),
    do: {Proxy.Chain, {:existing, id}}

  defp chain_child_spec(config) when is_map(config),
    do: {Proxy.Chain, {:new, config}}

  defp stack_workers(stacks) do
    IO.inspect("--------------------")
    IO.inspect(stacks)
    []
  end
end
