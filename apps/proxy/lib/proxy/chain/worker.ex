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

  use GenServer, restart: :transient

  require Logger

  alias Proxy.ExChain
  alias Proxy.Chain.Worker.State
  alias Proxy.Deployment.BaseApi

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

    Logger.debug("Started new chain #{id}")
    {:ok, _} = register(id)
    {:ok, %State{state | id: id}}
  end

  @doc false
  def init(%State{id: id, start: :existing} = state) when is_binary(id) do
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

    {:stop, :normal, %State{state | status: :terminated, chain_status: :terminated}}
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

    {:noreply, %State{state | chain_status: status}}
  end

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :started, data: details},
        %State{id: id, status: :starting, config: %{step_id: 0}} = state
      ) do
    Logger.debug("#{id}: Chain started successfully, have no deployment to perform")

    notify(state, :started, details)
    notify(state, :ready, details)

    {:noreply, %State{state | status: :ready, details: details}}
  end

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :started, data: details},
        %State{id: id, status: :starting, config: %{step_id: step}} = state
      ) do
    Logger.debug(
      "#{id}: Chain started successfully, have deployment to perform step: #{inspect(step)}"
    )

    # We have to notify that chain started
    notify(state, :started, details)
    new_state = deploy(step, %State{state | details: details})
    {:noreply, new_state, Application.get_env(:proxy, :deployment_timeout)}
  end

  @doc false
  def handle_info(
        %{__struct__: Chain.EVM.Notification, event: :started, data: details},
        %State{id: id, status: status} = state
      ) do
    Logger.debug("#{id}: Got chain :started event with worker status: #{status}")
    {:noreply, %State{state | details: details}}
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
    notify(id, :deployment_failed, "Timeout waiting deployment")
    notify(id, :failed)
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
  def handle_cast(
        {:deployment_finished, request_id, data},
        %State{id: id, status: :deploying} = state
      ) do
    Logger.debug("#{id}: Handling deployment #{request_id} finish #{inspect(data)}")
    notify(state, :deployed, data)
    notify(state, :ready)
    {:noreply, %State{state | status: :ready, deploy_data: data}}
  end

  @doc false
  def handle_cast(
        {:deployment_failed, request_id, msg},
        %State{id: id, status: :deploying} = state
      ) do
    Logger.debug("#{id}: Handling deployment #{request_id} finish #{inspect(msg)}")
    notify(state, :deploy_failed, msg)
    notify(state, :failed)
    {:noreply, %State{state | status: :failed}}
  end

  @doc false
  def handle_cast(
        {:deployment_finished, request_id, data},
        %State{id: id, status: status} = state
      ) do
    Logger.debug(
      "#{id}: Status #{status} Handling deployment #{request_id} finish #{inspect(data)}"
    )

    {:noreply, state}
  end

  @doc false
  def handle_call({:deploy, step}, _from, %State{} = state) do
    case deploy(step, state) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      {:error, err, new_state} ->
        {:reply, {:error, err}, new_state}
    end
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

  # Run deployment scripts
  defp deploy(_step, %State{details: nil} = state),
    do: {:error, "No chain details exist", state}

  defp deploy(step, %State{id: id, details: details} = state) do
    env = %{
      "ETH_RPC_URL" => Map.get(details, :rpc_url),
      "ETH_FROM" => Map.get(details, :coinbase),
      "ETH_RPC_ACCOUNTS" => "yes",
      "SETH_STATUS" => "yes",
      # "ETH_GAS" => Map.get(details, :gas_limit),
      "ETH_GAS" => "6000000"
    }

    request_id = BaseApi.random_id()
    Logger.debug("Starting deployment process with id: #{request_id}")

    case BaseApi.run(request_id, step, env) do
      {:ok, %{"type" => "ok"}} ->
        Logger.debug("Deployment process scheduled with request_id #{request_id} !")
        Proxy.Deployment.ProcessWatcher.put(request_id, id)

        # Notify UI that deployment started
        notify(state, :deploying, details)

        %State{state | status: :deploying}

      _ ->
        Logger.error("Failed to start deployment process with request id #{request_id}")
        notify(state, :error, %{message: "failed to start deployment process"})
        %State{state | status: :failed}
    end
  end

  defp notify(state, event, data \\ %{})

  defp notify(%State{notify_pid: nil}, _, _), do: :ok

  defp notify(%State{id: id, notify_pid: pid}, event, data),
    do: send(pid, %{id: id, event: event, data: data})
end
