defmodule Staxx.Testchain.EVM do
  @moduledoc """
  EVM abscraction. Each EVM have to implement this abstraction.
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.Helper
  alias Staxx.Testchain.Deployment.Result, as: DeploymentResult
  alias Staxx.Testchain.EVM.Config
  alias Staxx.Testchain.EVM.Implementation.{Geth, Ganache}
  alias Staxx.Testchain.AccountStore
  alias Staxx.Docker
  alias Staxx.Docker.Container
  alias Staxx.Store.Models.Chain, as: ChainRecord

  # Amount of ms the server is allowed to spend initializing or it will be terminated
  @timeout Application.get_env(:testchain, :kill_timeout, 60_000)

  @typedoc """
  List of EVM lifecircle statuses

  Meanings:

  - `:none` - Did nothing. Initial status
  - `:initializing` - Starting chain process (Not operational)
  - `:active` - Fully operational chain
  - `:terminating` - Termination process started (Not operational)
  - `:terminated` - Chain terminated (Not operational)
  - `:deploying` - Chain operational and deployment process started
  - `:deployment_failed` - Deployment process failed with error
  - `:deployment_success` - Deployment process sucessfuly finished
  - `:snapshot_taking` - EVM is stopping/stoped to make hard snapshot for evm DB. (Not operational)
  - `:snapshot_taken` - EVM took snapshot and now is in starting process (Not operational)
  - `:snapshot_reverting` - EVM stopping/stoped and in process of restoring snapshot (Not operational)
  - `:snapshot_reverted` - EVM restored snapshot and is in starting process (Not operational)
  - `:failed` - Critical error occured
  - `:ready` - Chain finished all tasks and totaly ready
  """
  @type status ::
          :none
          | :initializing
          | :active
          | :terminating
          | :terminated
          | :deploying
          | :deployment_failed
          | :deployment_success
          | :snapshot_taking
          | :snapshot_taken
          | :snapshot_reverting
          | :snapshot_reverted
          | :failed
          | :ready

  @doc """
  Callback that should return docker image for EVM
  """
  @callback docker_image() :: binary

  @doc """
  Callback will be called on chain starting after all internal modifications
  but before actual EVM start so
  this is correct place to make internal changes for concrete chain.
  For example you might replace `gas_limit` value for geth chain.
  """
  @callback migrate_config(Config.t()) :: Config.t()

  @doc """
  This callback is called on starting evm instance. 
  Here EVM should prepare all required files/accounts/other actions before it 
  actually will be started in docker container.

  In must return `{:ok, Container.t(), state}`, that `state` will be keept as in `GenServer` and can be
  retrieved in futher functions.
  """
  @callback start(config :: Config.t()) :: {:ok, Container.t(), state :: any()} | {:error, term()}

  @doc """
  Callback will be invoked after EVM started and confirmed it by `started?/2`
  Result will be internal state that will be stored for later use of implementation
  """
  @callback on_started(config :: Config.t(), state :: any()) :: state :: any()

  @doc """
  Callback will be called after EVM container start and system will assign ports to it.
  It have to pick correct ports from given ports list.
  Ports information might be found in `Staxx.Docker.Container.t()`.

  Result of this function have to be 2 ports for `{http_port, ws_port}`
  """
  @callback pick_ports([{host_port :: pos_integer, internal_port :: pos_integer}], state :: any()) ::
              {pos_integer, pos_integer}

  @doc """
  This callback will be called when system will need to stop EVM.
  Just before final EVM termination this function will be called as well.
  So it's nice place to stop some custom work you are doing on EVM.

  Note: This callback might be called several times during EVM life.
  On snapshot taking/revering EVM will be stopped and `on_stop/2` will be invoked.
  If you need final EVM termination consider using `on_terminate/2` callback

  Result value should be updated internal state
  """
  @callback on_stop(config :: Config.t(), state :: any()) :: any()

  @doc """
  This callback is called just before the Process goes down. 
  This is a good place for closing connections.

  Difference with `on_stop` is that `on_terminate` will be called on final EVM termination process.
  But `on_stop` might be called on tmp EVM stopping (example: makeing/reverting snapshot)
  """
  @callback on_terminate(config :: Config.t(), state :: any()) :: term()

  @doc """
  Get parsed version for EVM
  """
  @callback get_version() :: Version.t() | nil

  @doc """
  Callback will be called to get exact EVM version
  """
  @callback version() :: binary

  @doc """
  Child specification for supervising given `Staxx.Testchain.EVM` module
  """
  @spec child_spec(Config.t()) :: :supervisor.child_spec()
  def child_spec(%Config{type: :geth} = config), do: child_spec(Geth, config)

  def child_spec(%Config{type: :ganache} = config), do: child_spec(Ganache, config)

  def child_spec(%Config{type: _}), do: {:error, :unsuported_evm_type}

  @doc """
  Child specification for supervising given `Staxx.Testchain.EVM` module
  """
  @spec child_spec(module(), Config.t()) :: :supervisor.child_spec()
  def child_spec(module, %Config{id: id} = config) do
    %{
      id: "testchain_evm_#{id}",
      start: {module, :start_link, [config]},
      restart: :transient,
      shutdown: @timeout
    }
  end

  @doc """
  `{:via}` notation for process registry
  """
  @spec via(Testchain.evm_id()) :: {:via, Registry, {module, Testchain.evm_id()}}
  def via(id),
    # do: {:via, Registry, {EVMRegistry, id}}
    do: {:global, "evm_#{id}"}

  @doc """
  Will clean `db_path` if `clean_on_stop` is set to true
  And will remove container with given name
  Otherwise it will do nothing and will return `:ok`

  Note: Container remove error will be ignored.
  """
  @spec clean_on_stop(Config.t()) :: :ok | {:error, term()}
  def clean_on_stop(config)

  def clean_on_stop(%Config{clean_on_stop: false}), do: :ok

  def clean_on_stop(%Config{id: id, clean_on_stop: true, db_path: db_path}),
    do: clean(id, db_path)

  @doc """
  Notify EVM process that deployment finally finished
  """
  @spec handle_deployment_success(GenServer.server(), DeploymentResult.t()) :: :ok
  def handle_deployment_success(server, result),
    do: GenServer.cast(server, {:deployment_success, result})

  @doc """
  Notify EVM process that deployment failed
  """
  @spec handle_deployment_failed(GenServer.server(), term) :: :ok
  def handle_deployment_failed(server, data),
    do: GenServer.cast(server, {:deployment_failed, data})

  defmacro __using__(_opt) do
    # credo:disable-for-next-line
    quote do
      use GenServer, restart: :transient

      require Logger

      alias Staxx.JsonRpc
      alias Staxx.Testchain
      alias Staxx.Testchain.EVM
      alias Staxx.Testchain.EVM.{Account, Config, State}
      alias Staxx.Testchain.EVMRegistry
      alias Staxx.Testchain.{AccountStore, SnapshotManager}
      alias Staxx.Testchain.Supervisor, as: TestchainSupervisor
      alias Staxx.Testchain.Deployment.Result, as: DeploymentResult
      alias Staxx.Testchain.Deployment.StepsFetcher
      alias Staxx.Docker
      alias Staxx.Docker.Container
      alias Staxx.Store.Models.Chain, as: ChainRecord

      @behaviour EVM

      # Default deployment git reference
      @default_deploy_ref Application.get_env(:testchain, :default_deployment_scripts_git_ref)

      # maximum amount of checks for evm started
      # system checks if evm started every 200ms
      @max_start_checks 30 * 5

      # Amount of milliseconds we will wait EVM container to terminate.
      @evm_stop_timeout 60_000

      @doc false
      def start_link(%Config{id: nil}), do: {:error, :id_required}

      def start_link(%Config{id: id} = config) do
        GenServer.start_link(__MODULE__, config,
          name: unquote(__MODULE__).via(id),
          timeout: unquote(@timeout)
        )
      end

      @doc false
      def init(%Config{id: id, db_path: db_path, existing: true} = config) do
        version = get_version()

        # Send notification about status change
        Helper.notify_status(id, :initializing)

        {:ok, %State{status: :initializing, config: config, version: version},
         {:continue, :start_chain}}
      end

      @doc false
      def init(%Config{id: id, db_path: db_path, existing: false} = config) do
        # Check DB path existense
        unless File.exists?(db_path) do
          Logger.debug("#{id}: #{db_path} not exist, creating...")
          :ok = File.mkdir_p!(db_path)
        end

        # Binding newly created docker container name
        config =
          config
          |> Map.put(:container_name, Docker.random_name())
          |> migrate_config()

        version = get_version()

        # Writing chain to DB
        Helper.insert_or_update(id, config, :initializing)

        # Send notification about status change
        Helper.notify_status(id, :initializing)

        {:ok, %State{status: :initializing, config: config, version: version},
         {:continue, :start_chain}}
      end

      @doc false
      def terminate(
            reason,
            %State{
              config: config,
              internal_state: internal_state,
              container_pid: container_pid
            } = state
          ) do
        Logger.debug(fn -> "#{config.id}: Terminating evm with reason: #{inspect(reason)}" end)
        # Send notification about termnating
        Helper.notify_status(config.id, :terminating)
        # invoking callback for implementation
        # Note: we will totally ignore result
        on_terminate(config, internal_state)

        # stoping container in sync mode if it's alive
        if Process.alive?(container_pid) do
          Logger.debug(fn -> "#{config.id}: Shutting down container process" end)
          :ok = Container.stop(container_pid)
          Logger.debug(fn -> "#{config.id}: Container terminated" end)
        end

        # If exit reason is normal we could send notification that evm stopped
        case reason do
          r when r in ~w(normal shutdown)a ->
            # Removing stopped container
            rm_container(config.id, config.container_name)

            # Clean path for chain after it was terminated
            EVM.clean_on_stop(config)
            # Send notification after stop
            Helper.notify_status(config.id, :terminated)

          {:shutdown, reason} ->
            # Sending new error notification
            Helper.notify_error(config.id, "#{inspect(reason)}")
            # Termination was not planned. Seems to be failure
            Helper.notify_status(config.id, :failed)
        end

        # Send stop signal to Supervisor
        spawn(fn -> TestchainSupervisor.stop(config.id) end)
      end

      @doc """
      Starts EVM. 
      Called from all initialization process.
      TODO: More detailed info for implementation
      """
      def handle_continue(:start_chain, %State{config: config} = state) do
        case start(config) do
          {:ok, %Container{name: ""}, _} ->
            Logger.error(fn -> "#{config.id}: No container name for EVM container..." end)
            # Notify status change
            Helper.notify_status(config.id, :failed)
            {:stop, {:shutdown, :failed_to_start}, %State{state | status: :failed}}

          {:ok, %Container{name: container_name} = container, internal_state} ->
            Logger.debug(fn ->
              """
              #{config.id}: Chain initialization finished successfully ! 
              Starting container and waiting for JSON-RPC become operational.
              """
            end)

            # Handling Container termination
            Process.flag(:trap_exit, true)
            # Disable removing container after stop.
            # We might need to stop it and start again (ex: snapshots)
            # Container will be removed after termination. See: `terminate/2`
            container = %Container{container | rm: false}
            # Starting given container with EVM
            {:ok, container_pid} = Container.start_link(container)

            # Get container info for EVM
            %Container{ports: ports} = Container.info(container_pid)

            # Getting reserved by Docker ports
            {http_port, ws_port} = pick_ports(ports, internal_state)

            # Schedule started check
            # Operation is async and `status: :active` will be set later
            # See: `handle_info({:check_started, _})`
            check_started(self())

            # Storing testchain configuration because it wouldn't change anymore
            Logger.debug(fn -> "#{config.id}: Storing initial configuration for chain" end)

            # Updating config with container name
            config = %Config{config | container_name: container_name}
            # Storing new config
            Config.store(config)

            # Updating EVM state with new values
            state = %State{
              state
              | http_port: http_port,
                ws_port: ws_port,
                config: config,
                container_pid: container_pid,
                internal_state: internal_state
            }

            {:noreply, state}

          {:error, err} ->
            Logger.error("#{config.id}: on start: #{inspect(err)}")
            # Notify status change
            Helper.notify_status(config.id, :failed)
            {:stop, {:shutdown, :failed_to_start}, %State{state | status: :failed}}
        end
      end

      @doc """
      Callback is called after EVM started and became operational.
      It checks if we need to run any deployment, otherwise will finish initializing and mark chain as `:ready`
      """
      def handle_continue(:chain_active, %State{config: config} = state) do
        details = details(state)
        # Notify chain started
        Helper.notify_started(config.id, details)

        # Saving details
        Helper.store_chain_details(config.id, details)

        case Config.has_deployment?(config) do
          false ->
            Logger.debug(fn ->
              "#{config.id}: No deployment exist in configuration or started existing testchain. We are ready !"
            end)

            # TODO: start health checks

            # Notify status change
            Helper.notify_status(config.id, :ready)
            {:noreply, %State{state | status: :ready}}

          true ->
            Logger.debug(fn ->
              "#{config.id}: We have deployment step to run: #{config.deploy_step_id}"
            end)

            # Notify status change
            Helper.notify_status(config.id, :deploying)

            {:noreply, %State{state | status: :deploying},
             {:continue, {:run_deployment, details}}}
        end
      end

      @doc """
      Will start new deployment worker that will run deployment on deployment service
      """
      def handle_continue(
            {:run_deployment, details},
            %State{config: config, status: :deploying} = state
          ) do
        %Config{id: id, deploy_step_id: deploy_step} = config

        Logger.debug(fn ->
          "#{config.id}: New EVM started successfully, have deployment step to perform: #{
            deploy_step
          }"
        end)

        # Load step details
        with step when is_map(step) <- StepsFetcher.get(deploy_step),
             hash <- Map.get(config, :deploy_ref, @default_deploy_ref),
             {:ok, pid} <- Helper.run_deployment(id, self(), hash, deploy_step, details) do
          Logger.debug(fn ->
            "#{id}: Deployment process scheduled, worker pid: #{inspect(pid)} !"
          end)

          # Collecting telemetry
          :telemetry.execute(
            [:staxx, :chain, :deployment, :started],
            # %{request_id: request_id},
            %{},
            %{id: id, step_id: deploy_step}
          )

          # TODO: Store chain details

          # state
          # |> Record.from_state()
          # |> Record.chain_details(details)
          # |> Record.deploy_step(step)
          # |> Record.deploy_hash(hash)
          # |> Record.store()

          {:noreply, state}
        else
          err ->
            Logger.error(
              "#{id}: Failed to fetch steps from deployment service. Deploy ommited #{
                inspect(err)
              }"
            )

            Helper.notify_error(id, "failed to start deployment process")
            Helper.notify_status(id, :failed)
            {:stop, {:shutdown, :failed}, %State{state | status: :failed}}
        end
      end

      @doc false
      def handle_info({:EXIT, pid, reason}, %State{container_pid: container_pid} = state)
          when pid == container_pid do
        # Checking current status
        case Map.get(state, :status) do
          :terminating ->
            Logger.debug(fn -> "#{state.config.id}: EVM container terminates." end)
            {:stop, :normal, state}

          status ->
            Logger.warn(fn ->
              "#{state.config.id}: EVM container terminated with #{inspect(reason)}... Stopping..."
            end)

            {:stop, {:shutdown, :failed}, state}
        end
      end

      def handle_info({:EXIT, _, _} = msg, %State{config: config} = state) do
        Logger.debug(fn -> "#{config.id} EVM process handled unknown :EXIT #{inspect(msg)}" end)
        {:noreply, state}
      end

      @doc false
      def handle_info(:timeout, %State{config: %{id: id}, status: :terminating} = state) do
        Logger.warn("#{id}: EVM didn't stop after timeout ! Terminating...")
        {:stop, {:shutdown, :timeout}, state}
      end

      @doc false
      def handle_info(:timeout, %State{config: %{id: id}} = state) do
        Logger.warn("#{id}: Unknown timeout catched..")
        {:noreply, state}
      end

      def handle_info({:check_started, retries}, %State{config: config} = state)
          when retries >= @max_start_checks do
        msg = "#{config.id}: Fialed to start EVM. Alive checks failed"

        Logger.error(msg)
        # Have to notify about error to tell our supervisor to restart evm process
        Helper.notify_error(config.id, msg)
        # Notify status change
        Helper.notify_status(config.id, :failed)

        {:stop, {:shutdown, :failed_to_check_started}, %State{state | status: :failed}}
      end

      @doc false
      def handle_info(
            {:check_started, retries},
            %State{internal_state: internal_state, config: config} = state
          ) do
        Logger.debug("#{config.id}: Check if evm JSON RPC became operational")

        case started?(state) do
          true ->
            Logger.debug("#{config.id}: EVM Finally operational !")
            # Notify status change
            Helper.notify_status(config.id, :active)

            # Invoke `on_started/2` to notify EVM implementation about success start
            internal_state = on_started(config, internal_state)

            # Marking chain as started and operational
            {:noreply, %State{state | status: :active, internal_state: internal_state},
             {:continue, :chain_active}}

          false ->
            Logger.debug("#{config.id}: (#{retries}) not operational fully yet...")

            check_started(self(), retries + 1)
            {:noreply, state}
        end
      end

      @doc false
      def handle_info(msg, state) do
        Logger.debug("#{state.config.id}: Got msg #{inspect(msg)}")
        {:noreply, state}
      end

      @doc false
      def handle_call(:config, _from, %State{config: config, status: status} = state) do
        res =
          config
          |> Map.from_struct()
          |> Map.put(:status, status)

        {:reply, {:ok, res}, state}
      end

      @doc false
      def handle_call(:details, _from, %State{config: config} = state) do
        case details(config) do
          %EVM.Details{} = info ->
            {:reply, {:ok, info}, state}

          _ ->
            {:reply, {:error, "could not load details"}, state}
        end
      end

      @doc false
      def handle_cast(
            {:take_snapshot, description},
            %State{status: :ready, config: config, container_pid: container_pid} = state
          ) do
        Logger.debug(fn -> "#{config.id}: Stopping EVM before taking snapshot" end)

        unless Process.alive?(container_pid) do
          Helper.notify_error(
            config.id,
            "#{config.id}: Failed to take snapshot for non runing EVM"
          )

          raise "#{config.id}: Failed to take snapshot for non runing EVM"
        end

        # Notify status change
        Helper.notify_status(config.id, :snapshot_taking)

        # stoping container in sync mode if it's alive
        Logger.debug(fn -> "#{config.id}: Shutting down container process for taking snapshot" end)

        # TODO: pause health check for EVM
        container = Container.info(container_pid)
        :ok = Container.stop_temporary(container_pid)
        Logger.debug(fn -> "#{config.id}: Container terminated for taking snapshot" end)

        %Config{db_path: db_path, type: type} = config

        try do
          details = SnapshotManager.make_snapshot!(db_path, type, description)

          # Storing all snapshots
          SnapshotManager.store(details)

          Logger.debug("#{config.id}: Snapshot made, details: #{inspect(details)}")

          # Send notification with newly created snopshot details
          Helper.notify(config.id, :snapshot_taken, details)

          # Marking container as `existing` so no new container will be created
          # System will start already existing contianer and all ports/volumes 
          # will be already configured. So no need to change anything
          container = %Container{container | existing: true}
          # Starting given container with EVM
          {:ok, container_pid} = Container.start_link(container)

          # Notify status change
          Helper.notify_status(config.id, :snapshot_taken)

          # Schedule started check
          # Operation is async and `status: :active` will be set later
          # See: `handle_info({:check_started, _})`
          check_started(self())

          {:noreply, %State{state | status: :snapshot_taken, container_pid: container_pid}}
        rescue
          err ->
            Logger.error("#{config.id} failed to make snapshot with error #{inspect(err)}")
            # Send error notification
            Helper.notify_error(config.id, "failed to make snapshot with error #{inspect(err)}")
            # Notify status change
            Helper.notify_status(config.id, :failed)

            {:stop, :failed_take_snapshot, %State{state | status: :failed}}
        end
      end

      @doc false
      def handle_cast({:take_snapshot, _}, %State{config: config} = state) do
        Logger.error(fn ->
          "#{config.id}: No way we could take snapshot for non operational EVM"
        end)

        Helper.notify_error(config.id, "No way we could take snapshot for non operational EVM")
        {:noreply, state}
      end

      @doc false
      def handle_cast(
            {:revert_snapshot, snapshot},
            %State{status: :ready, config: config, container_pid: container_pid} = state
          ) do
        Logger.debug(fn -> "#{config.id}: Stopping EVM before reverting snapshot" end)

        unless Process.alive?(container_pid) do
          Helper.notify_error(
            config.id,
            "#{config.id}: Failed to revert snapshot for non runing EVM"
          )

          raise "#{config.id}: Failed to revert snapshot for non runing EVM"
        end

        # Notify status change
        Helper.notify_status(config.id, :snapshot_reverting)

        # stoping container in sync mode if it's alive
        Logger.debug(fn ->
          "#{config.id}: Shutting down container process for reverting snapshot"
        end)

        # TODO: pause health check for EVM
        container = Container.info(container_pid)
        :ok = Container.stop_temporary(container_pid)
        Logger.debug(fn -> "#{config.id}: Container terminated for reverting snapshot" end)

        %Config{db_path: db_path, type: type} = config

        try do
          details = SnapshotManager.restore_snapshot!(snapshot, db_path)

          Logger.debug("#{config.id}: Snapshot reverted, details: #{inspect(snapshot)}")

          # Send notification with newly created snopshot details
          Helper.notify(config.id, :snapshot_reverted, snapshot)

          # Marking container as `existing` so no new container will be created
          # System will start already existing contianer and all ports/volumes 
          # will be already configured. So no need to change anything
          container = %Container{container | existing: true}
          # Starting given container with EVM
          {:ok, container_pid} = Container.start_link(container)

          # Notify status change
          Helper.notify_status(config.id, :snapshot_reverted)

          # Schedule started check
          # Operation is async and `status: :active` will be set later
          # See: `handle_info({:check_started, _})`
          check_started(self())

          {:noreply, %State{state | status: :snapshot_reverted, container_pid: container_pid}}
        rescue
          err ->
            Logger.error("#{config.id} failed to revert snapshot with error #{inspect(err)}")
            # Send error notification
            Helper.notify_error(config.id, "failed to revert snapshot with error #{inspect(err)}")
            # Notify status change
            Helper.notify_status(config.id, :failed)

            {:stop, :failed_revert_snapshot, %State{state | status: :failed}}
        end
      end

      @doc false
      def handle_cast({:revert_snapshot, _}, %State{config: config} = state) do
        Logger.error(fn ->
          "#{config.id}: No way we could revert snapshot for non operational EVM"
        end)

        Helper.notify_error(config.id, "No way we could revert snapshot for non operational EVM")
        {:noreply, state}
      end

      @doc """
      Handling deployment process success
      """
      def handle_cast(
            {:deployment_success, %DeploymentResult{} = result},
            %State{config: config} = state
          ) do
        Logger.debug(fn -> "#{config.id}: Deployment process finished successfuly !" end)

        # Storing deployment result to DB
        Helper.store_deployment_result(config.id, result)

        # Sending required notifications
        Helper.notify_status(config.id, :deployment_success)
        Helper.notify(config.id, :deployment_success, result)
        Helper.notify_status(config.id, :ready)

        {:noreply, %State{state | status: :ready}}
      end

      @doc """
      Handling deployment process success
      """
      def handle_cast({:deployment_failed, data}, %State{config: config} = state) do
        Logger.debug(fn -> "#{config.id}: Deployment process failed !" end)
        Helper.notify_status(config.id, :deployment_failed)
        Helper.notify(config.id, :deployment_failed, inspect(data))

        # Marking chain as ready. Because may be we need to make other calls to EVM
        Helper.notify_status(config.id, :ready)

        {:noreply, %State{state | status: :ready}}
      end

      ######
      #
      # Default implementation functions for any EVM
      #
      ######
      @impl EVM
      def pick_ports([{http_port, _}, {ws_port, _}], _),
        do: {http_port, ws_port}

      def pick_ports(_, _),
        do: raise(ArgumentError, "Wrong input ports for EVM")

      @impl EVM
      def get_version() do
        version()
        |> Version.parse()
        |> case do
          {:ok, version} ->
            version

          _ ->
            Logger.error("#{__MODULE__} Failed to parse version for geth")
            nil
        end
      end

      @impl EVM
      def migrate_config(config), do: config

      @impl EVM
      def on_stop(_, state), do: state

      @impl EVM
      def on_terminate(config, state),
        do: Logger.debug("#{config.id}: Terminating... #{inspect(state, pretty: true)}")

      @impl EVM
      def on_started(_config, internal_state),
        do: internal_state

      @impl EVM
      def version() do
        docker_image()
        |> String.split(":")
        |> List.last()
      end

      ########
      #
      # Private functions for EVM
      #
      ########

      # Check if EVM started and operational
      defp started?(%State{config: %Config{id: id}, http_port: http_port}) do
        Logger.debug("#{id}: Checking if EVM started")

        case JsonRpc.eth_coinbase("http://localhost:#{http_port}") do
          {:ok, <<"0x", _::binary>>} ->
            true

          _ ->
            false
        end
      end

      # Get chain details by config
      defp details(%State{config: config, http_port: http_port, ws_port: ws_port}) do
        %Config{
          id: id,
          db_path: db_path,
          network_id: network_id,
          gas_limit: gas_limit
        } = config

        # Making request using async to not block scheduler
        [{:ok, coinbase}, {:ok, accounts}] =
          [
            # NOTE: here we will use localhost to avoid calling to chain from outside
            Task.async(fn -> JsonRpc.eth_coinbase("http://localhost:#{http_port}") end),
            Task.async(fn -> load_accounts(db_path) end)
          ]
          |> Enum.map(&Task.await/1)

        %EVM.Details{
          id: id,
          network_id: network_id,
          coinbase: coinbase,
          accounts: accounts,
          gas_limit: gas_limit,
          rpc_url: "http://#{front_url()}:#{http_port}",
          ws_url: "ws://#{front_url()}:#{ws_port}"
        }
      end

      # Send msg to check if evm started
      # Checks when EVM is started in async mode.
      defp check_started(pid, retries \\ 0),
        do: Process.send_after(pid, {:check_started, retries}, 200)

      # Store initial accounts
      # will return given accoutns
      defp store_accounts(accounts, db_path) do
        AccountStore.store(db_path, accounts)
        accounts
      end

      # Load list of initial accoutns from storage
      defp load_accounts(db_path),
        do: AccountStore.load(db_path)

      # Get front url for chain
      defp front_url(), do: Application.get_env(:testchain, :front_url)

      defp rm_container(_id, ""), do: :ok

      # Remove container after termination
      defp rm_container(id, name) do
        Logger.debug(fn -> "#{id}: Removing container #{name}" end)

        case Docker.rm(name) do
          :ok ->
            Logger.debug(fn -> "#{id}: Container removed." end)
            :ok

          {:error, err} ->
            Logger.error(fn -> "#{id}: Failed to remove container #{name}: #{inspect(err)}" end)
            {:error, err}
        end
      end

      # Allow to override functions
      defoverridable pick_ports: 2,
                     migrate_config: 1,
                     get_version: 0,
                     version: 0,
                     on_started: 2,
                     on_stop: 2,
                     on_terminate: 2
    end
  end

  ####################################################
  # Staxx.Testchain.EVM private functions
  ####################################################

  # Clean given path
  defp clean(_id, ""), do: :ok

  defp clean(id, db_path) do
    Logger.debug(fn -> "#{id}: Removing data from DB" end)
    ChainRecord.delete(id)

    Logger.debug(fn -> "#{id}: Removing data files #{db_path}" end)

    case File.rm_rf(db_path) do
      {:error, err} ->
        Logger.error("#{id}: Failed to clean up #{db_path} with error: #{inspect(err)}")
        {:error, err}

      _ ->
        Logger.debug("#{id}: Cleaned path after termination #{db_path}")
        :ok
    end
  end
end
