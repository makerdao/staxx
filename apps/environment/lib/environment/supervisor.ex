defmodule Staxx.Environment.Supervisor do
  @moduledoc """
  Supervises everything inside Environment.

  Part of is will be:
   - `testchain` - Exact EVM that will be started for environment
   - list of `stacks` - set of stack workers that controls different stacks
  """
  use Supervisor

  require Logger

  alias Staxx.Environment
  alias Staxx.Environment.Terminator
  alias Staxx.Environment.StacksSupervisor
  alias Staxx.Environment.EnvironmentRegistry

  @doc false
  def child_spec({id, _, _} = params) do
    %{
      id: "environment_supervisor_#{id}",
      start: {__MODULE__, :start_link, [params]},
      restart: :temporary,
      type: :supervisor
    }
  end

  @doc """
  Start new supervision tree for newly created environment.
  """
  def start_link({id, _chain_config_or_id, stacks} = params) do
    res = Supervisor.start_link(__MODULE__, params, name: via_tuple(id))

    # have to start stacks here. Because need to be sure that testchain
    # already started, before starting stacks.
    if {:ok, pid} = res do
      pid
      |> Supervisor.which_children()
      |> Enum.find(fn {_, _, _, [module]} -> module == get_testchain_supervisor_module() end)
      |> case do
        nil ->
          Logger.warn("#{id}: No #{get_testchain_supervisor_module()} child found...")

        {_, pid, _, _} ->
          Terminator.monitor(pid)
      end

      start_stacks(id, stacks)
    end

    res
  end

  @impl true
  def init({id, chain_config_or_id, _stacks}) do
    children = [
      get_testchain_supervisor_module().child_spec({id, chain_config_or_id}),
      StacksSupervisor.child_spec(id)
    ]

    opts = [strategy: :rest_for_one, max_restarts: 0]
    Supervisor.init(children, opts)
  end

  @doc """
  Generate naming via tuple for supervisor
  """
  @spec via_tuple(binary) :: {:via, Registry, {EnvironmentRegistry, binary}}
  def via_tuple(id),
    do: {:via, Registry, {EnvironmentRegistry, id}}

  @doc """
  Get `StacksSupervisor` instance binded to this environment.
  """
  @spec get_stack_manager_supervisor(binary) :: pid | nil
  def get_stack_manager_supervisor(environment_id) do
    res =
      environment_id
      |> via_tuple()
      |> Supervisor.which_children()
      |> Enum.find(nil, fn {_, _pid, _, [module]} -> module == StacksSupervisor end)

    case res do
      {_, pid, _, _} ->
        pid

      _ ->
        nil
    end
  end

  @doc """
  Starts new `Stack` in environment for `stack_name`.
  """
  @spec start_stack(binary, binary) :: DynamicSupervisor.on_start_child()
  def start_stack(environment_id, stack_name) do
    case Environment.alive?(environment_id) do
      false ->
        {:error, "No working environment with such id found"}

      true ->
        environment_id
        |> get_stack_manager_supervisor()
        |> StacksSupervisor.start_manager(environment_id, stack_name)
    end
  end

  #######################################
  # Private functions
  #######################################

  defp get_testchain_supervisor_module(),
    do: Application.get_env(:environment, :testchain_supervisor_module)

  # Start list of stacks
  defp start_stacks(environment_id, stacks) do
    stacks
    |> Map.keys()
    |> Enum.uniq()
    |> Enum.map(&start_stack(environment_id, &1))
  end
end
