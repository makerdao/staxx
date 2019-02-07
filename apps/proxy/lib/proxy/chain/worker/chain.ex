defmodule Proxy.Chain.Worker.Chain do
  @moduledoc """
  Most of chani action will be here
  """

  require Logger

  alias Proxy.Chain.Storage
  alias Proxy.Chain.Worker.{Notifier, State}
  alias Proxy.Deployment.BaseApi
  alias Proxy.Deployment.StepsFetcher

  @doc """
  Load stored chain details and if details loaded they will be merged with 
  passed state, otherwise given state will be returned unchanged
  """
  @spec merge_existing_state(Proxy.Chain.Worker.State.t()) :: Proxy.Chain.Worker.State.t()
  def merge_existing_state(%State{id: id} = state) do
    case Storage.get(id) do
      %{id: ^id} = loaded_state ->
        loaded_state
        |> Map.merge(Map.drop(state, [:deploy_data, :deploy_step, :deploy_hash, :config]))

      _ ->
        state
    end
  end

  @doc """
  Handle EVM started event.

  Next we have to perform set of steps.
  - If we started existing chain - no deployemnt have to be performed and status set to `:ready`
  - If we started new chain and set deployment step in config - we have to perform deployment and status set to `:deploying`
  - If we started new chain and no deployment step is set - we have to do nothing and status set to `:ready`
  """
  @spec handle_evm_started(Proxy.Chain.Worker.State.t(), map()) :: Proxy.Chain.Worker.State.t()
  def handle_evm_started(%State{id: id, start: :existing} = state, details) do
    Logger.debug("#{id}: Existing chain started successfully, have no deployment to perform")

    Notifier.notify(state, :started, details)
    Notifier.notify(state, :ready, details)
    # Combining new state
    new_state = %State{state | status: :ready, chain_details: details}
    # Send relayer notification
    Notifier.notify_oracles(new_state)

    new_state
  end

  def handle_evm_started(
        %State{id: id, start: :new, status: :starting, config: %{step_id: 0}} = state,
        details
      ) do
    Logger.debug("#{id}: New EVM started successfully, have no deployment to perform")

    Notifier.notify(state, :started, details)
    Notifier.notify(state, :ready, details)

    %State{state | status: :ready, chain_details: details}
  end

  def handle_evm_started(
        %State{id: id, start: :new, status: :starting, config: %{step_id: step_id}} = state,
        details
      ) do
    Logger.debug(
      "#{id}: New EVM started successfully, have deployment step to perform: #{step_id}"
    )

    # We have to notify that chain started
    Notifier.notify(state, :started, details)

    # Load step details
    with step when is_map(step) <- StepsFetcher.get(step_id),
         hash when byte_size(hash) > 0 <- StepsFetcher.hash(),
         new_state <- %State{state | chain_details: details, deploy_step: step, deploy_hash: hash},
         {:ok, request_id} <- run_deployment(step_id, new_state) do
      Logger.debug("Deployment process scheduled with request_id #{request_id} !")
      # Save deployment request association with current chain
      Proxy.Deployment.ProcessWatcher.put(request_id, id)
      # Notify UI that deployment started
      Notifier.notify(state, :deploying, details)
      %State{state | status: :deploying}
      # {:noreply, new_state, Application.get_env(:proxy, :deployment_timeout)}
    else
      _ ->
        Logger.error("#{id}: Failed to fetch steps from deployment service. Deploy ommited")
        Notifier.notify(state, :error, %{message: "failed to start deployment process"})
        Notifier.notify(state, :ready, details)
        %State{state | status: :ready}
    end
  end

  def handle_evm_started(%State{} = state, details),
    do: %State{state | chain_details: details}

  @doc """
  handler for deployment finished
  """
  @spec handle_deployment_finished(Proxy.Chain.Worker.State.t(), binary, map()) ::
          Proxy.Chain.Worker.State.t()
  def handle_deployment_finished(%State{id: id, status: :deploying} = state, request_id, data) do
    Logger.debug("#{id}: Handling deployment #{request_id} finish #{inspect(data)}")
    Notifier.notify(state, :deployed, data)
    Notifier.notify(state, :ready)

    new_state = %State{state | status: :ready, deploy_data: data}

    Logger.debug("#{id}: Send oracles notification")
    res = Notifier.notify_oracles(new_state)
    Logger.debug("#{id}: Notify oracles result: #{inspect(res)}")

    new_state
  end

  def handle_deployment_finished(%State{id: id, status: status} = state, _request_id, data) do
    Logger.debug("#{id}: Deployment finished event for status: #{status}, #{inspect(data)}")
    state
  end

  @doc """
  Run deployment scripts for chain
  """
  @spec run_deployment(1..9, Proxy.Chain.Worker.State.t()) :: Proxy.Chain.Worker.State.t()
  def run_deployment(_step_id, %State{chain_details: nil}),
    do: {:error, "No chain details exist"}

  def run_deployment(step_id, %State{id: id, chain_details: details}) do
    request_id = BaseApi.random_id()
    Logger.debug("#{id}: Starting deployment process with id: #{request_id}")

    env = %{
      "ETH_RPC_URL" => Map.get(details, :rpc_url),
      "ETH_FROM" => Map.get(details, :coinbase),
      "ETH_RPC_ACCOUNTS" => "yes",
      "SETH_STATUS" => "yes",
      # "ETH_GAS" => Map.get(details, :gas_limit),
      "ETH_GAS" => "6000000"
    }

    case BaseApi.run(request_id, step_id, env) do
      {:ok, %{"type" => "ok"}} ->
        {:ok, request_id}

      _ ->
        {:error, "failed to start deployment"}
    end
  end
end
