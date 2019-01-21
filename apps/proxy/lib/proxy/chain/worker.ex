defmodule Proxy.Chain.Worker do
  @moduledoc """
  Chain/deployment/other tasks performer. 

  All tasksthat will iteract with chain should go through this worker.
  """

  use GenServer, restart: :transient

  require Logger

  alias Proxy.ExChain
  alias Proxy.Chain.Worker.State

  @doc false
  def start_link({:existing, id, pid}) when is_binary(id),
    do: GenServer.start_link(__MODULE__, %State{id: id, action: :existing, notify_pid: pid})

  def start_link({:new, %{id: id} = config, pid}) when is_map(config),
    do:
      GenServer.start_link(__MODULE__, %State{
        id: id,
        action: :new,
        config: config,
        notify_pid: pid
      })

  @doc false
  def init(%State{id: id, action: :new, config: config} = state) do
    Logger.debug("Starting new chain #{Map.get(config, :type)}")

    {:ok, ^id} =
      config
      |> Map.put(:notify_pid, self())
      |> ExChain.start()

    Logger.debug("Started new chain #{id}")
    {:ok, _} = register(id)
    {:ok, %State{state | id: id}}
  end

  @doc false
  def init(%State{id: id, action: :existing} = state) when is_binary(id) do
    Logger.debug("#{id}: Loading chain details")
    {:ok, ^id} = ExChain.start_existing(id, self())
    Logger.debug("#{id}: Starting existing chain")
    {:ok, _} = register(id)
    {:ok, state}
  end

  @doc false
  def terminate(_, %State{id: id}) do
    ExChain.stop(id)
  end

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :status_changed, data: :terminated} = event,
        %State{id: id} = state
      ) do
    Logger.debug("#{id}: Chain stopped going down")

    if pid = Map.get(state, :notify_pid) do
      send(pid, event)
    end

    {:stop, :normal, %State{state | status: :terminated}}
  end

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :status_changed, data: status} = event,
        %State{id: id} = state
      ) do
    Logger.debug("#{id}: Chain status changed to #{status}")

    if pid = Map.get(state, :notify_pid) do
      send(pid, event)
    end

    {:noreply, %State{state | status: status}}
  end

  @doc false
  def handle_info(%{__struct__: Chain.EVM.Notification} = event, state) do
    if pid = Map.get(state, :notify_pid) do
      send(pid, event)
    end

    {:noreply, state}
  end

  @doc false
  def handle_info(msg, state) do
    {:noreply, state}
  end

  @doc false
  def handle_cast(:stop, %State{id: id} = state) do
    Logger.debug("#{id} Terminating chain")
    ExChain.stop(id)
    {:noreply, state}
  end

  @doc """
  Get GenServer pid by id
  """
  @spec get_pid(binary) :: nil | pid()
  def get_pid(id) do
    case Registry.lookup(Proxy.ChainRegistry, id) do
      [{pid, _}] ->
        pid

      _ ->
        nil
    end
  end

  # via tuple generation
  defp register(id),
    do: Registry.register(Proxy.ChainRegistry, id, nil)
end
