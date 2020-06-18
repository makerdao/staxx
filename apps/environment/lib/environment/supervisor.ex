defmodule Staxx.Environment.Environment.Supervisor do
  @moduledoc """
  Supervises everything inside Environment.

  Part of is will be:
   - `testchain` - Exact EVM that will be started for environment
   - list of `extensions` - set of extension workers that controls different extensions
  """
  use Supervisor

  require Logger

  alias Staxx.Environment
  alias Staxx.Environment.Terminator
  alias Staxx.Environment.ExtensionsSupervisor
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
  def start_link({id, _chain_config_or_id, extensions} = params) do
    res = Supervisor.start_link(__MODULE__, params, name: via_tuple(id))

    # have to start extension managers here. Because need to be sure that testchain
    # already started, before starting extensions.
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

      start_extensions(id, extensions)
    end

    res
  end

  @impl true
  def init({id, chain_config_or_id, _extensions}) do
    children = [
      get_testchain_supervisor_module().child_spec({id, chain_config_or_id}),
      ExtensionsSupervisor.child_spec(id)
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
  Get `ExtensionsSupervisor` instance binded to this environment.
  """
  @spec get_extension_manager_supervisor(binary) :: pid | nil
  def get_extension_manager_supervisor(environment_id) do
    res =
      environment_id
      |> via_tuple()
      |> Supervisor.which_children()
      |> Enum.find(nil, fn {_, _pid, _, [module]} -> module == ExtensionsSupervisor end)

    case res do
      {_, pid, _, _} ->
        pid

      _ ->
        nil
    end
  end

  @doc """
  Starts new `Extension` in environment for `extension_name`.
  """
  @spec start_extension(binary, binary) :: DynamicSupervisor.on_start_child()
  def start_extension(environment_id, extension_name) do
    case Environment.alive?(environment_id) do
      false ->
        {:error, "No working environment with such id found"}

      true ->
        environment_id
        |> get_extension_manager_supervisor()
        |> ExtensionsSupervisor.start_manager(environment_id, extension_name)
    end
  end

  #######################################
  # Private functions
  #######################################

  defp get_testchain_supervisor_module(),
    do: Application.get_env(:environment, :testchain_supervisor_module)

  # Start list of extension managers
  defp start_extensions(environment_id, extensions) do
    extensions
    |> Map.keys()
    |> Enum.uniq()
    |> Enum.map(&start_extension(environment_id, &1))
  end
end
