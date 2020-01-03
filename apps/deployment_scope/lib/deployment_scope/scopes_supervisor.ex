defmodule Staxx.DeploymentScope.ScopesSupervisor do
  @moduledoc """
  Supervisor that will manage all deployment scopes
  """

  # Automatically defines child_spec/1
  use DynamicSupervisor

  require Logger

  alias Staxx.DeploymentScope.Scope.DeploymentScopeSupervisor

  @doc false
  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)
  end

  @doc """
  Start new supervision tree for deployment scope.

  System will start new supervision tree with all required modules in correct order
  For more details see `Staxx.DeploymentScope.Scope.Supervisor`
  """
  @spec start_scope({binary, binary | map, map}) :: DynamicSupervisor.on_start_child()
  def start_scope({_id, _chain, _stacks} = params),
    do: DynamicSupervisor.start_child(__MODULE__, {DeploymentScopeSupervisor, params})

  @doc """
  Stops Supervision tree for given deployment scope id
  """
  @spec stop_scope(binary) :: :ok | {:error, term}
  def stop_scope(id) when is_binary(id) do
    id
    |> DeploymentScopeSupervisor.via_tuple()
    |> GenServer.whereis()
    |> case do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      res ->
        Logger.error(fn ->
          "#{__MODULE__}: Failed to find pid for #{inspect(id)}, found: #{inspect(res)}"
        end)
    end
  end
end
