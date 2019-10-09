defmodule Staxx.DeploymentScope.Deployment.Worker do
  @moduledoc """
  Wroker that will controll deployment process flow.
  It will spawn new deployment worker (docker container) with all reaquired info
  and will handle deployment results.

  Required information for deployment:
  - request id
  - deploy step_id (scenario_id)
  - deploy scripts repo url
  - deploy scripts tag/branch
  - staxx url (where to send results)
  - chain details (coinbase, gas limit, rpc_url)

  """
  use GenServer, restart: :transient

  # Timeout 20 mins in ms
  @timeout 20 * 60 * 60 * 1000

  require Logger

  alias Staxx.DeploymentScope.EVMWorker
  alias Staxx.DeploymentScope.DeploymentRegistry
  alias Staxx.DeploymentScope.Deployment.{Config, BaseApi}
  alias Staxx.Docker.Struct.Container

  @doc """
  Start new deployment process
  """
  @spec start_link(Config.t()) :: GenServer.on_start()
  def start_link(%Config{scope_id: ""}),
    do: {:error, "Wrong scope id"}

  def start_link(%Config{coinbase: ""}),
    do: {:error, "Wrong coinbase"}

  def start_link(%Config{rpc_url: ""}),
    do: {:error, "Wrong rpc url"}

  def start_link(%Config{request_id: ""} = config) do
    %Config{config | request_id: BaseApi.random_id()}
    |> start_link()
  end

  def start_link(%Config{gas_limit: limit} = config) when not is_binary(limit) do
    %Config{config | gas_limit: inspect(limit)}
    |> start_link()
  end

  def start_link(%Config{request_id: request_id} = config),
    do: GenServer.start_link(__MODULE__, config, name: via_tuple(request_id))

  @doc false
  def init(%Config{scope_id: id} = config) do
    Logger.debug(fn ->
      "#{id}: Starting new deployment worker with config: #{inspect(config, pretty: true)}"
    end)

    # We need to handle container exit status
    Process.flag(:trap_exit, true)
    {:ok, config, {:continue, :spawn_worker}}
  end

  @doc false
  def handle_continue(:spawn_worker, %Config{scope_id: id} = config) do
    config
    |> build_container()
    |> Container.start_link()
    |> case do
      {:error, err} ->
        Logger.error(fn ->
          "#{id}: Failed to start new deployment worker container process: #{inspect(err)}"
        end)

        {:stop, :normal, config}

      _ ->
        Logger.debug(fn -> "Started new deployment worker container process" end)
        {:noreply, config, @timeout}
    end
  end

  @doc false
  def handle_cast({:failed, data}, %Config{scope_id: id, request_id: request_id} = config) do
    Logger.debug("Chain #{id} need to handle deployment request")
    EVMWorker.handle_deployment_failure(id, request_id, data)
    {:stop, :normal, config}
  end

  @doc false
  def handle_cast({:finsihed, result}, %Config{scope_id: id, request_id: request_id} = config) do
    Logger.debug("Chain #{id} need to handle deployment request")
    EVMWorker.handle_deployment(id, request_id, result)
    {:stop, :normal, config}
  end

  def handle_info(:timeout, %Config{scope_id: id} = config) do
    Logger.debug(fn -> "#{id}: Deployment worker received timeout for deployment" end)
    {:stop, :timeout, config}
  end

  @doc false
  def handle_info({:EXIT, _from, :normal}, config) do
    Logger.debug(fn -> "Deployment worker container successfully terminated" end)
    {:stop, :normal, config}
  end

  @doc false
  def handle_info({:EXIT, _from, reason}, config) do
    Logger.info(fn -> "Deployment worker contaner terminated with reason: #{inspect(reason)}" end)
    {:stop, :normal, config}
  end

  @doc false
  def terminate(reason, %Config{scope_id: id}) do
    Logger.debug(fn ->
      "#{id}: Deployment worker process terminating with reason: #{inspect(reason)}"
    end)

    :ok
  end

  @doc """
  Prepare container structure for running deployment scripts
  """
  @spec build_container(Config.t()) :: Container.t()
  def build_container(%Config{
        scope_id: id,
        request_id: request_id,
        rpc_url: rpc_url,
        coinbase: coinbase,
        gas_limit: gas_limit,
        git_url: git_url,
        git_ref: git_ref,
        step_id: step_id
      }) do
    %Container{
      # it will terminate and we don't need to fail on it
      permanent: false,
      dev_mode: true,
      image: docker_image(),
      network: id,
      volumes: ["nix-db:/nix"],
      env: %{
        "REQUEST_ID" => request_id,
        "DEPLOY_ENV" => chain_env(rpc_url, coinbase, gas_limit),
        "REPO_URL" => git_url,
        "REPO_REF" => git_ref,
        "SCENARIO_NR" => step_id,
        "TCD_GATEWAY" => "host=#{host()}",
        "TCD_NATS" => "servers=nats://host.docker.internal:4222"
      }
    }
  end

  @doc """
  Notify that deployment process failed
  """
  @spec deployment_failed(binary, term) :: :ok
  def deployment_failed(request_id, data) do
    request_id
    |> via_tuple()
    |> GenServer.cast({:failed, data})
  end

  @doc """
  Notify that deployment process finished
  """
  @spec deployment_finished(binary, term) :: :ok
  def deployment_finished(request_id, result) do
    request_id
    |> via_tuple()
    |> GenServer.cast({:finished, result})
  end

  # Combine deployment ENV vars for chain
  defp chain_env(rpc_url, coinbase, gas_limit) do
    %{
      "ETH_RPC_URL" => rpc_url,
      "ETH_FROM" => coinbase,
      "ETH_RPC_ACCOUNTS" => "yes",
      "ETH_GAS" => gas_limit
    }
    |> Poison.encode!()
  end

  defp via_tuple(request_id),
    do: {:via, Registry, {DeploymentRegistry, request_id}}

  defp host(),
    do: Application.get_env(:deployment_scope, :host, "host.docker.internal")

  defp docker_image(),
    do: Application.get_env(:deployment_scope, :deployment_worker_image)
end
