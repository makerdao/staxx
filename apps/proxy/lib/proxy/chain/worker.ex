defmodule Proxy.Chain.Worker do
  @moduledoc """
  Chain/deployment/other tasks performer.

  All tasksthat will iteract with chain should go through this worker.

  Worker has it's own statuses a bit different to ExTestchain

  When new worker is spawning it's status is set to `:starting` then flow is this:
  `:starting` -> `:started` -> `:deploying` -> `:deployed` -> `:ready`
  So chain is fully ready only when status is set to `:ready`
  In case of failure status will be set to `:failed`
  """

  @type status :: :starting | :started | :deploying | :deployed | :ready | :failed | :terminated

  use GenServer, restart: :transient

  require Logger

  alias Proxy.ExChain
  alias Proxy.Chain.Worker.{State, Notifier, Chain}
  alias Proxy.Chain.Storage

  @doc false
  def start_link({:existing, id, pid}) when is_binary(id),
    do: GenServer.start_link(__MODULE__, %State{id: id, start: :existing, notify_pid: pid})

  def start_link({:new, %{id: id} = config, pid}) when is_map(config) do
    GenServer.start_link(__MODULE__, %State{
      id: id,
      start: :new,
      config: config,
      notify_pid: pid
    })
  end

  @doc false
  def init(%State{id: id, start: :new, config: config} = state) do
    Logger.debug("Starting new chain #{Map.get(config, :type)}")

    {:ok, ^id} =
      config
      |> Map.put(:notify_pid, self())
      |> ExChain.to_config()
      |> ExChain.start()

    Logger.debug("#{id}: Started new chain")
    {:ok, _} = register(id)
    # Store new chain worker
    Storage.store(%State{state | id: id})
    {:ok, %State{state | id: id}}
  end

  @doc false
  def init(%State{id: id, start: :existing} = state) when is_binary(id) do
    Logger.debug("#{id}: Loading chain details")
    {:ok, ^id} = ExChain.start_existing(id, self())
    Logger.debug("#{id}: Started existing chain")
    {:ok, _} = register(id)

    state = Chain.merge_existing_state(state)
    Logger.debug("#{id}: existing state merged to: #{inspect(state)}")
    # Store updated chain state
    Storage.store(state)
    {:ok, state}
  end

  @doc false
  def terminate(_, %State{id: id}), do: ExChain.stop(id)

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :status_changed, data: :terminated},
        %State{id: id} = state
      ) do
    Logger.debug("#{id}: EVM stopped, going down")
    Notifier.notify(state, :terminated)

    # Send kill relayer signal
    Proxy.Oracles.Api.remove_relayer()
    new_state = %State{state | status: :terminated, chain_status: :terminated}
    # Storing state
    Storage.store(new_state)
    {:stop, :normal, new_state}
  end

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :status_changed, data: status} = event,
        %State{id: id} = state
      ) do
    Logger.debug("#{id}: EVM status changed to #{status}")

    if pid = Map.get(state, :notify_pid) do
      send(pid, event)
    end

    {:noreply, %State{state | chain_status: status}}
  end

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :started, data: details},
        state
      ) do
    new_state = Chain.handle_evm_started(state, details)
    Storage.store(new_state)

    case new_state do
      %State{status: :deploying} ->
        # If deployment process started we have to set timeout
        {:noreply, new_state, Application.get_env(:proxy, :deployment_timeout)}

      _ ->
        {:noreply, new_state}
    end
  end

  @doc false
  def handle_info(%{__struct__: Chain.EVM.Notification} = event, state) do
    if pid = Map.get(state, :notify_pid) do
      send(pid, event)
    end

    {:noreply, state}
  end

  @doc false
  def handle_info(:timeout, %State{id: id, status: :deploying} = state) do
    Logger.error("#{id}: Waiting deployment failed: timeout")
    Notifier.notify(id, :deployment_failed, "Timeout waiting deployment")
    Notifier.notify(id, :failed)
    Storage.store(%State{state | status: :failed})
    {:noreply, %State{state | status: :failed}}
  end

  @doc false
  def handle_info(msg, %State{id: id} = state) do
    Logger.debug("#{id}: Handled message #{inspect(msg)}")
    {:noreply, state}
  end

  @doc false
  def handle_cast(:stop, %State{id: id} = state) do
    Logger.debug("#{id} Terminating chain")
    ExChain.stop(id)
    {:noreply, state}
  end

  @doc false
  def handle_cast({:deployment_finished, request_id, data}, state) do
    new_state = Chain.handle_deployment_finished(state, request_id, data)
    Storage.store(new_state)
    {:noreply, new_state}
  end

  @doc false
  def handle_cast(
        {:deployment_failed, request_id, msg},
        %State{id: id, status: :deploying} = state
      ) do
    Logger.debug("#{id}: Handling deployment #{request_id} finish #{inspect(msg)}")
    Notifier.notify(state, :deploy_failed, msg)
    Notifier.notify(state, :failed)
    Storage.store(%State{state | status: :failed})
    {:noreply, %State{state | status: :failed}}
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

  @doc """
  Handle deployment by chain worker
  """
  @spec handle_deployment(binary, binary, term()) :: term()
  def handle_deployment(id, request_id, data) do
    with pid when is_pid(pid) <- get_pid(id) do
      GenServer.cast(pid, {:deployment_finished, request_id, data})
    end
  end

  @doc """
  Send deployment failure event to worker
  """
  @spec handle_deployment_failure(binary, binary, map()) :: term()
  def handle_deployment_failure(id, request_id, %{"msg" => msg, "stderrB64" => err}) do
    with pid when is_pid(pid) <- get_pid(id) do
      decoded_err = Base.decode64!(err)
      Logger.error("#{id}: Deployment failed\n #{decoded_err}")

      GenServer.cast(pid, {:deployment_failed, request_id, msg})
    end
  end

  # via tuple generation
  defp register(id),
    do: Registry.register(Proxy.ChainRegistry, id, nil)
end
