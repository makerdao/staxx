defmodule Proxy.Chain.Worker do
  @moduledoc """
  Chain/deployment/other tasks performer.

  All tasksthat will iteract with chain should go through this worker.
  """
  use GenServer, restart: :transient

  require Logger

  alias Proxy.ExChain
  alias Proxy.Chain.Worker.{State, ChainHelper}
  alias Proxy.Chain.Storage.Record
  alias Chain.EVM.Notification

  @doc false
  def start_link({:existing, id, pid}) when is_binary(id) do
    state = %State{id: id, start: :existing, notify_pid: pid}
    GenServer.start_link(__MODULE__, {state, nil})
  end

  def start_link({:new, %{id: id} = config, pid}) when is_map(config) do
    state = %State{
      id: id,
      start: :new,
      notify_pid: pid,
      deploy_step_id: Map.get(config, :step_id, 0)
    }

    GenServer.start_link(__MODULE__, {state, config})
  end

  @doc false
  def init({%State{id: id, node: nil} = state, config}) do
    case Proxy.NodeManager.node() do
      nil ->
        Logger.error("#{id}: No free ex_testchain node for starting EVM.")
        {:error, :no_free_node}

      node ->
        Logger.debug("#{id}: Node to start EVM selected: #{inspect(node)}")

        new_state =
          state
          |> State.node(node)

        init({new_state, config})
    end
  end

  @doc false
  def init({%State{id: id, node: node, start: :new} = state, config}) do
    Logger.debug("Starting new chain #{Map.get(config, :type)}")

    evm_config =
      config
      |> Map.put(:notify_pid, self())
      |> ExChain.to_config()

    {:ok, ^id} = ExChain.start(node, evm_config)

    Logger.debug("#{id}: Started new chain")
    {:ok, _} = register(id)

    # Store new chain worker
    state
    |> Record.from_state()
    |> Record.config(config)
    |> Record.store()

    {:ok, state}
  end

  @doc false
  def init({%State{id: id, node: node, start: :existing} = state, _}) when is_binary(id) do
    Logger.debug("#{id}: Loading chain details")
    {:ok, ^id} = ExChain.start_existing(node, id, self())
    Logger.debug("#{id}: Started existing chain")
    {:ok, _} = register(id)

    Logger.debug("#{id}: existing state merged to: #{inspect(state)}")

    # Store updated chain state
    state
    |> Record.from_state()
    |> Record.store()

    {:ok, state}
  end

  @doc false
  def terminate(_, %State{id: id, node: node}), do: ExChain.stop(node, id)

  @doc false
  def handle_continue(:deployment_failed, state) do
    new_state =
      state
      |> State.notify(:deployment_failed, "Timeout waiting deployment")
      |> State.notify(:failed)
      |> State.status(:failed)
      |> State.store()

    {:noreply, new_state}
  end

  @doc false
  def handle_info(
        %Notification{event: :status_changed, data: :terminated},
        %State{id: id} = state
      ) do
    Logger.debug("#{id}: EVM stopped, going down")

    # Send kill relayer signal
    Proxy.Oracles.Api.remove_relayer()

    new_state =
      state
      |> State.status(:terminated)
      |> State.chain_status(:terminated)
      |> State.notify(:terminated)
      |> State.store()

    {:stop, :normal, new_state}
  end

  @doc false
  def handle_info(
        %Notification{event: :status_changed, data: :active},
        %State{id: id, notify_pid: pid} = state
      ) do
    Logger.debug("#{id}: EVM status changed to active")

    if pid do
      send(pid, %Notification{id: id, event: :active})
    end

    {:noreply, %State{state | chain_status: :active}}
  end

  @doc false
  def handle_info(
        %Notification{event: :status_changed, data: status},
        %State{id: id} = state
      ) do
    Logger.debug("#{id}: EVM status changed to #{status}")
    {:noreply, %State{state | chain_status: status}}
  end

  @doc false
  def handle_info(
        %Notification{event: :started, data: details},
        state
      ) do
    new_state = ChainHelper.handle_evm_started(state, details)

    case new_state do
      %State{status: :initializing} ->
        # If deployment process started we have to set timeout
        {:noreply, new_state, Application.get_env(:proxy, :deployment_timeout)}

      _ ->
        {:noreply, new_state}
    end
  end

  @doc false
  def handle_info(%Notification{} = event, state) do
    if pid = Map.get(state, :notify_pid) do
      send(pid, event)
    end

    {:noreply, state}
  end

  @doc false
  def handle_info(:timeout, %State{id: id, status: :initializing} = state) do
    Logger.error("#{id}: Waiting deployment failed: timeout")

    {:noreply, state, {:continue, :deployment_failed}}
  end

  @doc false
  def handle_info(msg, %State{id: id} = state) do
    Logger.debug("#{id}: Handled message #{inspect(msg)}")
    {:noreply, state}
  end

  @doc false
  def handle_call(:node, _from, %State{node: node} = state),
    do: {:reply, node, state}

  def handle_call({:take_snapshot, description}, _from, %State{id: id, node: node} = state) do
    resp = ExChain.take_snapshot(node, id, description)
    {:reply, resp, state}
  end

  def handle_call({:revert_snapshot, snapshot_id}, _from, %State{id: id, node: node} = state) do
    with {:load, snapshot} when is_map(snapshot) <-
           {:load, ExChain.load_snapshot(node, snapshot_id)},
         :ok <- ExChain.revert_snapshot(node, id, snapshot) do
      Logger.debug("#{id}: Reverting snapshot #{snapshot_id}")
      {:reply, :ok, state}
    else
      {:load, err} ->
        Logger.error("Failed to load snapshot details #{inspect(err)}")
        {:reply, {:error, "failed to load snapshot details #{snapshot_id}"}, state}

      _ ->
        Logger.error("#{id}: failed to revert snapshot #{snapshot_id}")
        {:reply, {:error, "something wrong on reverting snapshot #{snapshot_id}"}, state}
    end
  end

  @doc false
  def handle_cast(:stop, %State{id: id, node: node} = state) do
    Logger.debug("#{id} Terminating chain")
    ExChain.stop(node, id)
    {:noreply, state}
  end

  @doc false
  def handle_cast({:deployment_finished, request_id, data}, state) do
    new_state = ChainHelper.handle_deployment_finished(state, request_id, data)
    {:noreply, new_state}
  end

  @doc false
  def handle_cast(
        {:deployment_failed, request_id, msg},
        %State{id: id, status: :initializing} = state
      ) do
    Logger.debug("#{id}: Handling deployment #{request_id} finish #{inspect(msg)}")

    {:noreply, state, {:continue, :deployment_failed}}
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
