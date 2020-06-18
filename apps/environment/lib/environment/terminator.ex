defmodule Staxx.Environment.Terminator do
  @moduledoc """
  Terminator is here for tracking scope health and in case of testchain failure
  it will kill whole scope. But it wouldn't be back...
  """
  use GenServer

  require Logger

  alias Staxx.Environment.DynamicSupervisor, as: EnvironmentsDynamicSupervisor

  @doc false
  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc false
  def init(_) do
    Logger.debug(fn -> "#{__MODULE__}: Come with me if you want to live..." end)
    {:ok, :ok}
  end

  @doc false
  def handle_cast({:monitor, pid}, :ok) do
    Logger.debug(fn ->
      "#{__MODULE__}: #{inspect(pid)} I need your clothes, your boots, and your motorcycle"
    end)

    Process.monitor(pid)
    {:noreply, :ok}
  end

  @doc false
  def handle_info({:DOWN, ref, :process, pid, reason}, :ok) do
    Logger.debug(fn ->
      "#{__MODULE__}: #{inspect(pid)} termination handled with reason: #{inspect(reason)}"
    end)

    case reason do
      r when r in ~w(normal shutdown)a ->
        Logger.debug(fn ->
          "#{__MODULE__}: Everything is good. Supervisor terminates everything."
        end)

      {:shutdown, id} ->
        EnvironmentsDynamicSupervisor.stop_environment(id)
        Logger.debug(fn -> "#{__MODULE__}: Hasta la vista, baby #{id}" end)

      _ ->
        Logger.debug(fn ->
          "#{__MODULE__}: unknown reason #{inspect(reason)} for #{inspect(pid)} "
        end)
    end

    Process.demonitor(ref)
    {:noreply, :ok}
  end

  @doc """
  Start monitoring `Staxx.Testchain.Supervisor` pid.
  """
  @spec monitor(pid) :: :ok
  def monitor(pid),
    do: GenServer.cast(__MODULE__, {:monitor, pid})
end
