defmodule Proxy.Chain.Worker.ChainHelper do
  @moduledoc """
  Most of chani action will be here
  """

  require Logger

  alias Proxy.Chain.Worker.State
  alias Proxy.Deployment.StepsFetcher
  alias Proxy.Chain.Storage.Record

  # List of events that should be resend to event bus
  @proxify_events [:active, :snapshot_taking, :snapshot_reverting]

  @doc """
  Handle EVM started event.

  Next we have to perform set of steps.
  - If we started existing chain - no deployemnt have to be performed and status set to `:ready`
  - If we started new chain and set deployment step in config - we have to perform deployment and status remain `:initializing`
  - If we started new chain and no deployment step is set - we have to do nothing and status set to `:ready`
  """
  @spec handle_evm_started(Proxy.Chain.Worker.State.t(), map()) :: Proxy.Chain.Worker.State.t()
  def handle_evm_started(%State{id: id, start: :existing} = state, details) do
    Logger.debug("#{id}: Existing chain started successfully, have no deployment to perform")

    # record =
    state
    |> Record.from_state()
    |> Record.status(:ready)
    |> Record.chain_details(details)
    |> Record.store()

    # Send relayer notification
    # spawn(OraclesApi, :notify_new_chain, [record])

    # Combining new state
    state
    |> State.status(:ready)
    |> State.notify(:ready, details)
  end

  def handle_evm_started(
        %State{id: id, start: :new, status: :initializing, deploy_step_id: 0} = state,
        details
      ) do
    Logger.debug("#{id}: New EVM started successfully, have no deployment to perform")

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
        %State{id: id, start: :new, status: :initializing, deploy_step_id: step_id} = state,
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
  @spec handle_deployment_finished(Proxy.Chain.Worker.State.t(), binary, map()) ::
          Proxy.Chain.Worker.State.t()
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

    # Send relayer notification
    # spawn(OraclesApi, :notify_new_chain, [record])

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
  @spec handle_chain_status_change(Proxy.Chain.Worker.State.t(), atom) ::
          Proxy.Chain.Worker.State.t()
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
end
