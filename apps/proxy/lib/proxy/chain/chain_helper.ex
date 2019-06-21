defmodule Proxy.Chain.ChainHelper do
  @moduledoc """
  Most of chani action will be here
  """

  require Logger

  alias Chain.EVM.Notification
  alias Proxy.ExChain
  alias Proxy.Chain.State
  alias Proxy.Deployment.StepsFetcher
  alias Proxy.Chain.Storage.Record

  # List of events that should be resend to event bus
  @proxify_events [:active, :snapshot_taking, :snapshot_reverting]

  @doc """
  Convert payload (from POST) to valid chain config
  """
  @spec chain_config_from_payload(map) :: map
  def chain_config_from_payload(payload) when is_map(payload) do
    %{
      type: String.to_atom(Map.get(payload, "type", "ganache")),
      # id: Map.get(payload, "id"),
      # http_port: Map.get(payload, "http_port"),
      # ws_port: Map.get(payload, "ws_port"),
      # db_path: Map.get(payload, "db_path", ""),
      network_id: Map.get(payload, "network_id", 999),
      accounts: Map.get(payload, "accounts", 1),
      block_mine_time: Map.get(payload, "block_mine_time", 0),
      clean_on_stop: Map.get(payload, "clean_on_stop", false),
      description: Map.get(payload, "description", ""),
      snapshot_id: Map.get(payload, "snapshot_id"),
      deploy_tag: Map.get(payload, "deploy_tag"),
      step_id: Map.get(payload, "step_id", 0)
    }
  end

  @doc """
  Locks execution before message will be received from chain
  """
  @spec wait_chain_event(binary, atom, pos_integer) :: map | :timeout
  def wait_chain_event(id, event, timeout \\ 30_000) do
    receive do
      %Notification{id: ^id, event: ^event} = msg ->
        msg

      _ ->
        wait_chain_event(id, event, timeout)
    after
      timeout ->
        :timeout
    end
  end

  @doc """
  Handle EVM started event.

  Next we have to perform set of steps.
  - If we started existing chain - no deployemnt have to be performed and status set to `:ready`
  - If we started new chain and set deployment step in config - we have to perform deployment and status remain `:initializing`
  - If we started new chain and no deployment step is set - we have to do nothing and status set to `:ready`
  """
  @spec handle_evm_started(State.t(), map()) :: State.t()
  def handle_evm_started(%State{id: id, start_type: :existing} = state, details) do
    Logger.debug("#{id}: Existing chain started successfully, have no deployment to perform")

    state
    |> Record.from_state()
    |> Record.status(:ready)
    |> Record.chain_details(details)
    |> Record.store()

    # Combining new state
    state
    |> State.status(:ready)
    |> State.notify(:ready, details)
  end

  def handle_evm_started(
        %State{id: id, start_type: :new, status: :initializing, deploy_step_id: 0} = state,
        details
      ) do
    Logger.debug("#{id}: New EVM started successfully, have no deployment to perform")

    state
    |> Record.from_state()
    |> Record.status(:ready)
    |> Record.chain_details(details)
    # We have to load deploy data only here.
    # Because in other cases it will be filled by deploy afterwards
    |> read_deploy_data_to_record(state)
    |> Record.store()

    # Combining new state
    state
    |> State.status(:ready)
    |> State.notify(:ready, details)
  end

  def handle_evm_started(
        %State{id: id, start_type: :new, status: :initializing, deploy_step_id: step_id} = state,
        details
      ) do
    Logger.debug(
      "#{id}: New EVM started successfully, have deployment step to perform: #{step_id}"
    )

    # Load step details
    with step when is_map(step) <- StepsFetcher.get(step_id),
         hash when byte_size(hash) > 0 <- StepsFetcher.hash(),
         {:ok, request_id} <- run_deployment(state, step_id, details) do
      Logger.debug("Deployment process scheduled with request_id #{request_id} !")
      # Save deployment request association with current chain
      Proxy.Deployment.ProcessWatcher.put(request_id, id)

      state
      |> Record.from_state()
      |> Record.chain_details(details)
      |> Record.deploy_step(step)
      |> Record.deploy_hash(hash)
      |> Record.store()

      # Notify UI that deployment started
      state
      |> State.chain_status(:started)
      |> State.notify(:deploying, details)
    else
      err ->
        Logger.error(
          "#{id}: Failed to fetch steps from deployment service. Deploy ommited #{inspect(err)}"
        )

        state
        |> State.status(:failed)
        |> State.notify(:error, %{message: "failed to start deployment process"})
        |> State.notify(:failed)
        |> State.store()
    end
  end

  def handle_evm_started(%State{} = state, details) do
    state
    |> Record.from_state()
    |> Record.chain_details(details)
    |> Record.store()

    %State{state | chain_status: :started}
  end

  @doc """
  handler for deployment finished
  """
  @spec handle_deployment_finished(State.t(), binary, map()) :: State.t()
  def handle_deployment_finished(
        %State{id: id, status: :initializing, deploy_step_id: step_id} = state,
        request_id,
        data
      )
      when step_id > 0 do
    Logger.debug("#{id}: Handling deployment #{request_id} finish #{inspect(data)}")

    # Loading stored data and updating with new
    record =
      state
      |> Record.from_state()
      |> Record.status(:ready)
      |> Record.deploy_data(data)
      |> Record.store()

    Logger.debug("#{id}: Writing deployment details to external chain data")
    # Write deployment details to chain as external data.
    # It will be read on starting chain from snapshot
    write_deploy_data(state, record)

    state
    |> State.status(:ready)
    |> State.notify(:ready, Map.get(record, :chain_details, %{}))
    |> State.notify(:deployed, data)
  end

  def handle_deployment_finished(%State{id: id, status: status} = state, _request_id, data) do
    Logger.debug("#{id}: Deployment finished event for status: #{status}, #{inspect(data)}")
    state
  end

  @doc """
  Handle chain status update
  """
  @spec handle_chain_status_change(State.t(), atom) :: State.t()
  def handle_chain_status_change(state, status)
      when status in @proxify_events do
    state
    |> State.notify(status)
  end

  def handle_chain_status_change(%State{id: id} = state, status) do
    Logger.debug("#{id}: Unhandled EVM status: #{status}")
    state
  end

  @doc """
  Run deployment scripts for chain
  """
  @spec run_deployment(State.t(), 1..9, map()) :: {:ok, term} | {:error, term}
  def run_deployment(%State{id: id, deploy_tag: tag}, step_id, %{
        rpc_url: rpc_url,
        coinbase: coinbase
      }),
      do: Proxy.Deployment.Deployer.deploy(id, step_id, rpc_url, coinbase, tag)

  def run_deployment(_state, _step_id, _details),
    do: {:error, "No chain details exist"}

  @doc """
  Write deployment data as external chain data
  """
  @spec write_deploy_data(State.t(), map) :: :ok | {:error, term}
  def write_deploy_data(%State{node: nil}, _data), do: :ok

  def write_deploy_data(%State{node: node, id: id}, %Record{} = data),
    do: ExChain.write_external_data(node, id, {:deploy, %Record{data | id: nil, status: nil}})

  def write_deploy_data(_, _), do: {:error, "wrong deployment details"}

  @doc """
  Load deployment data from chain
  """
  @spec read_deploy_data(State.t()) ::
          {:ok, nil}
          | {:ok, Record.t()}
          | {:error, term}
  def read_deploy_data(%State{id: id, node: node}) do
    case ExChain.read_external_data(node, id) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, {:deploy, data}} ->
        {:ok, data}

      {:error, err} ->
        {:error, err}

      _ ->
        {:error, "Wrong details loaded"}
    end
  end

  # Read deploy data and merge it into given record details
  defp read_deploy_data_to_record(%Record{} = record, %State{id: id} = state) do
    case read_deploy_data(state) do
      {:ok, %Record{} = loaded} ->
        Logger.debug("#{id}: We have loaded deploy details from storage. #{inspect(loaded)}")

        record
        |> Record.merge_deploy_details(loaded)

      _ ->
        record
    end
  end
end
