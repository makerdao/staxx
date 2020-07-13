defmodule Staxx.Environment.DynamicSupervisor do
  @moduledoc """
  Supervisor that will manage all environments
  """

  # Automatically defines child_spec/1
  use DynamicSupervisor

  require Logger

  alias Staxx.Environment.Supervisor, as: EnvironmentSupervisor

  @doc false
  def start_link(arg),
    do: DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)

  @impl true
  def init(_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)

  @doc """
  Start new supervision tree for new Environment.

  System will start new supervision tree with all required modules in correct order
  For more details see `Staxx.Environment.Scope.Supervisor`
  """
  @spec start_environment({binary, binary | map, map}) :: DynamicSupervisor.on_start_child()
  def start_environment({_id, _chain, _stacks} = params),
    do: DynamicSupervisor.start_child(__MODULE__, {EnvironmentSupervisor, params})

  @doc """
  Stops Supervision tree for environment with given id
  """
  @spec stop_environment(binary) :: :ok | {:error, term}
  def stop_environment(id) when is_binary(id) do
    id
    |> EnvironmentSupervisor.via_tuple()
    |> GenServer.whereis()
    |> case do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      res ->
        Logger.error(fn ->
          "#{__MODULE__}: Failed to find supervisor pid for environment #{inspect(id)}, found: #{
            inspect(res)
          }"
        end)
    end
  end
end
