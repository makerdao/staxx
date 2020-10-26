defmodule Staxx.Instance.DynamicSupervisor do
  @moduledoc """
  Supervisor that will manage all instances
  """

  # Automatically defines child_spec/1
  use DynamicSupervisor

  require Logger

  alias Staxx.Instance.Supervisor, as: InstanceSupervisor

  @doc false
  def start_link(arg),
    do: DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)

  @impl true
  def init(_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 0)

  @doc """
  Start new supervision tree for new Instance.

  System will start new supervision tree with all required modules in correct order
  For more details see `Staxx.Instance.Scope.Supervisor`
  """
  @spec start_instance({binary, binary | map, map}) :: DynamicSupervisor.on_start_child()
  def start_instance({_id, _chain, _stacks} = params),
    do: DynamicSupervisor.start_child(__MODULE__, {InstanceSupervisor, params})

  @doc """
  Stops Supervision tree for instance with given id
  """
  @spec stop_instance(binary) :: :ok | {:error, term}
  def stop_instance(id) when is_binary(id) do
    id
    |> InstanceSupervisor.via_tuple()
    |> GenServer.whereis()
    |> case do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      res ->
        Logger.error(fn ->
          "#{__MODULE__}: Failed to find supervisor pid for instance #{inspect(id)}, found: #{
            inspect(res)
          }"
        end)
    end
  end
end
