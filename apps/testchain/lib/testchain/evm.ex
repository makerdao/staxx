defmodule Staxx.Testchain.EVM do
  @moduledoc """
  EVM abscraction. Each EVM have to implement this abstraction.
  """

  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.Helper
  alias Staxx.Testchain.EVM.Config
  alias Staxx.Testchain.EVM.Implementation.{Geth, Ganache}
  alias Staxx.Testchain.AccountStore
  alias Staxx.Docker.Container

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

  # @typedoc """
  # Task that should be performed.

  # Some tasks require chain to be stopped before performing
  # like, taking/reverting snapshots, changing initial evm configs.
  # such tasks should be set into `State.task` and after evm termination
  # system will perform this task and try to start chain again
  # """
  # @type scheduled_task ::
  #         nil
  #         | {:take_snapshot, description :: binary}
  #         | {:revert_snapshot, SnapshotDetails.t()}

  @typedoc """
  Default evm action reply message
  """
  @type action_reply ::
          :ok
          | :ignore
          | {:ok, state :: any()}
          | {:noreply, state :: any()}
          | {:reply, reply :: term(), state :: any()}
          | {:error, term()}

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
  Callback will be called after EVM container start and system will assign ports to it.
  It have to pick correct ports from given ports list.
  Ports information might be found in `Staxx.Docker.Container.t()`.

  Result of this function have to be 2 ports for `{http_port, ws_port}`
  """
  @callback pick_ports([{host_port :: pos_integer, internal_port :: pos_integer}], state :: any()) ::
              {pos_integer, pos_integer}

  @doc """
  This callback will be called when system will need to stop EVM.
  Just before actual EVM termination this function will be called.
  So it's nice place to stop some custom work you are doing on EVM.

  Result value should be updated internal state
  """
  @callback pre_stop(config :: Config.t(), state :: any()) :: any()

  @doc """
  Callback will be invoked after EVM started and confirmed it by `started?/2`
  """
  @callback handle_started(config :: Config.t(), state :: any()) :: action_reply()

  @doc """
  This callback is called just before the Process goes down. This is a good place for closing connections.
  """
  @callback on_terminate(config :: Config.t(), state :: any()) :: term()

  @doc """
  Load list of initial accounts
  Should return list of initial accounts for chain.
  By default they will be stored into `{db_path}/addresses.json` file in JSON format

  Reply should be in format
  `{:ok, [Staxx.Testchain.EVM.Account.t()]} | {:error, term()}`
  """
  @callback initial_accounts(config :: Config.t(), state :: any()) :: action_reply()

  @doc """
  Get parsed version for EVM
  """
  @callback get_version() :: Version.t() | nil

  @doc """
  Callback will be called to get exact EVM version
  """
  @callback version() :: binary

  @doc """
  Child specification for supervising given `Testchain.EVM` module
  """
  @spec child_spec(Config.t()) :: :supervisor.child_spec()
  def child_spec(%Config{type: :geth} = config), do: child_spec(Geth, config)

  def child_spec(%Config{type: :ganache} = config), do: child_spec(Ganache, config)

  def child_spec(%Config{type: _}), do: {:error, :unsuported_evm_type}

  @doc """
  Child specification for supervising given `Chain.EVM` module
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
  Will clean `db_path` if `clean_on_stop` is set to true
  Otherwise it will do nothing and will return `:ok`
  """
  @spec clean_on_stop(Config.t()) :: :ok | {:error, term()}
  def clean_on_stop(%Config{clean_on_stop: false}), do: :ok

  def clean_on_stop(%Config{id: id, clean_on_stop: true, db_path: db_path}),
    do: clean(id, db_path)

  @doc """
  Cleans given path
  """
  @spec clean(ExChain.evm_id(), binary) :: :ok | {:error, term}
  def clean(id, db_path) do
    case File.rm_rf(db_path) do
      {:error, err} ->
        Logger.error("#{id}: Failed to clean up #{db_path} with error: #{inspect(err)}")
        {:error, err}

      _ ->
        Logger.debug("#{id}: Cleaned path after termination #{db_path}")
        :ok
    end
  end

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
      alias Staxx.Testchain.AccountStore
      alias Staxx.Testchain.Supervisor, as: TestchainSupervisor
      alias Staxx.Docker
      alias Staxx.Docker.Container

      @behaviour EVM

      # maximum amount of checks for evm started
      # system checks if evm started every 200ms
      @max_start_checks 30 * 5

      # Amount of milliseconds we will wait EVM container to terminate.
      @evm_stop_timeout 60_000

      @doc false
      def start_link(%Config{id: nil}), do: {:error, :id_required}

      def start_link(%Config{id: id} = config) do
        GenServer.start_link(__MODULE__, config,
          name: via(id),
          timeout: unquote(@timeout)
        )
      end

      @doc false
      def init(%Config{id: id, db_path: db_path} = config) do
        # Check DB path existense
        unless File.exists?(db_path) do
          Logger.debug("#{id}: #{db_path} not exist, creating...")
          :ok = File.mkdir_p!(db_path)
        end

        new_config = migrate_config(config)
        version = get_version()

        # Send notification about status change
        Helper.notify_status(id, :initializing)

        {:ok, %State{status: :initializing, config: new_config, version: version},
         {:continue, :start_chain}}
      end

      @doc false
      def handle_continue(:start_chain, %State{config: config} = state) do
        case start(config) do
          {:ok, %Container{} = container, internal_state} ->
            Logger.debug(fn ->
              """
              #{config.id}: Chain initialization finished successfully ! 
              Starting container and waiting for JSON-RPC become operational.
              """
            end)

            # Handling Container termination
            Process.flag(:trap_exit, true)
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

      @doc false
      def handle_continue(
            :stop,
            %State{config: config, container_pid: pid, internal_state: internal_state} = state
          ) do
        Logger.debug(fn -> "#{config.id}: Stopping EVM container." end)

        # Calling pre stop function to stop something.
        new_internal_state = pre_stop(config, internal_state)

        # Terminating container
        :ok = Container.terminate(pid)

        # Notify status change
        Helper.notify_status(config.id, :terminating)

        new_state = %State{state | status: :terminating, internal_state: new_internal_state}

        # Stop timeout
        {:noreply, new_state, @evm_stop_timeout}
      end

      @doc false
      # method will be called after snapshot for evm was taken and EVM switched to `:snapshot_taken` status.
      # here evm will be started again
      # def handle_continue(
      #       :start_after_task,
      #       %State{status: status, config: config} = state
      #     )
      #     when status in ~w(snapshot_taken snapshot_reverted)a do
      #   Logger.debug("#{config.id} Starting chain after #{status}")
      #   # Start chain process
      #   {:ok, new_internal_state} = start(config)
      #   # Schedule started check
      #   # Operation is async and `status: :active` will be set later
      #   # See: `handle_info({:check_started, _})`
      #   check_started(self())
      #   {:noreply, State.internal_state(state, new_internal_state)}
      # end

      @doc false
      def handle_info(
            {:EXIT, pid, reason},
            %State{container_pid: container_pid} = state
          ) do
        case pid do
          ^container_pid ->
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

          _ ->
            {:noreply, state}
        end
      end

      def handle_info({:EXIT, _, _} = msg, %State{config: config} = state) do
        Logger.warn(fn -> "#{config.id} EVM process handled unknown :EXIT #{inspect(msg)}" end)
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
            # Notify chain started
            Helper.notify_started(config.id, details(state))

            config
            |> handle_started(internal_state)
            # Marking chain as started and operational
            |> handle_action(%State{state | status: :active})

          false ->
            Logger.debug("#{config.id}: (#{retries}) not operational fully yet...")

            check_started(self(), retries + 1)
            {:noreply, state}
        end
      end

      # @doc false
      # def handle_info(
      #       {_, :result, %Porcelain.Result{status: signal}},
      #       %State{
      #         status: :snapshot_taking,
      #         task: {:take_snapshot, description},
      #         config: config
      #       } = state
      #     ) do
      #   %Config{id: id, db_path: db_path, type: type} = config
      #   Logger.debug("#{id}: Chain terminated for taking snapshot with exit status: #{signal}")

      #   try do
      #     details = SnapshotManager.make_snapshot!(db_path, type, description)

      #     # Storing all snapshots
      #     SnapshotManager.store(details)

      #     Logger.debug("#{id}: Snapshot made, details: #{inspect(details)}")

      #     new_state =
      #       state
      #       |> State.status(:snapshot_taken, config)
      #       |> State.task(nil)

      #     Notification.send(config, id, :snapshot_taken, details)

      #     {:noreply, new_state, {:continue, :start_after_task}}
      #   rescue
      #     err ->
      #       Logger.error("#{id} failed to make snapshot with error #{inspect(err)}")
      #       {:stop, :failed_take_snapshot, State.status(state, :failed, config)}
      #   end
      # end

      # @doc false
      # def handle_info(
      #       {_, :result, %Porcelain.Result{status: signal}},
      #       %State{
      #         status: :snapshot_reverting,
      #         task: {:revert_snapshot, snapshot},
      #         config: config
      #       } = state
      #     ) do
      #   %Config{id: id, db_path: db_path, type: type} = config
      #   Logger.debug("#{id}: Chain terminated for reverting snapshot with exit status: #{signal}")

      #   try do
      #     :ok = SnapshotManager.restore_snapshot!(snapshot, db_path)
      #     Logger.debug("#{id}: Snapshot reverted")

      #     Notification.send(config, id, :snapshot_reverted, snapshot)

      #     new_state =
      #       state
      #       |> State.status(:snapshot_reverted, config)
      #       |> State.task(nil)

      #     {:noreply, new_state, {:continue, :start_after_task}}
      #   rescue
      #     err ->
      #       Logger.error(
      #         "#{id} failed to revert snapshot #{inspect(snapshot)} with error #{inspect(err)}"
      #       )

      #       # {:noreply, State.status(state, :failed, config)}
      #       {:stop, :failed_restore_snapshot, State.status(state, :failed, config)}
      #   end
      # end

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
      def handle_call(
            :initial_accounts,
            _from,
            %State{config: config, internal_state: internal_state} = state
          ) do
        config
        |> initial_accounts(internal_state)
        |> handle_action(state)
      end

      @doc false
      def handle_call(:details, _from, %State{config: config} = state) do
        case details(config) do
          %EVM.Process{} = info ->
            {:reply, {:ok, info}, state}

          _ ->
            {:reply, {:error, "could not load details"}, state}
        end
      end

      @doc false
      # def handle_cast(
      #       {:take_snapshot, description},
      #       %State{status: :active, locked: false, config: config, internal_state: internal_state} =
      #         state
      #     ) do
      #   Logger.debug("#{config.id} stopping emv before taking snapshot")
      #   {:ok, new_internal_state} = stop(config, internal_state)

      #   new_state =
      #     state
      #     |> State.status(:snapshot_taking, config)
      #     |> State.task({:take_snapshot, description})
      #     |> State.internal_state(new_internal_state)

      #   {:noreply, new_state}
      # end

      @doc false
      def handle_cast({:take_snapshot, _}, state) do
        Logger.error("No way we could take snapshot for non operational or locked evm")
        {:noreply, state}
      end

      @doc false
      # def handle_cast(
      #       {:revert_snapshot, snapshot},
      #       %State{status: :active, locked: false, config: config, internal_state: internal_state} =
      #         state
      #     ) do
      #   Logger.debug("#{config.id} stopping emv before reverting snapshot")
      #   {:ok, new_internal_state} = stop(config, internal_state)

      #   new_state =
      #     state
      #     |> State.status(:snapshot_reverting, config)
      #     |> State.task({:revert_snapshot, snapshot})
      #     |> State.internal_state(new_internal_state)

      #   {:noreply, new_state}
      # end

      @doc false
      def handle_cast({:revert_snapshot, _}, state) do
        Logger.error("No way we could revert snapshot for non operational or locked evm")
        {:noreply, state}
      end

      @doc false
      def handle_cast(:stop, %State{} = state),
        do: {:noreply, state, {:continue, :stop}}

      @doc false
      def terminate(
            reason,
            %State{config: config, internal_state: internal_state, container_pid: container_pid} =
              state
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
          :ok = Container.terminate(container_pid)
          Logger.debug(fn -> "#{config.id}: Coontainer terminated" end)
        end

        # If exit reason is normal we could send notification that evm stopped
        case reason do
          r when r in ~w(normal shutdown)a ->
            # Clean path for chain after it was terminated
            Testchain.EVM.clean_on_stop(config)
            # Send notification after stop
            Helper.notify_status(config.id, :terminated)

          {:shutdown, reason} ->
            # Sending new error notification
            Helper.notify_error(config.id, "#{inspect(reason)}")
            # Termination was not planned. Seems to be failure
            Helper.notify_status(config.id, :failed)
        end

        # Send stop signal to Supervisor
        # Task.async(fn -> TestchainSupervisor.stop(config.id) end)
        spawn(fn -> TestchainSupervisor.stop(config.id) end)
      end

      @doc """
      `{:via}` notation for process registry
      """
      @spec via(Testchain.evm_id()) :: {:via, Registry, {module, Testchain.evm_id()}}
      def via(id),
        # do: {:via, Registry, {EVMRegistry, id}}
        do: {:global, "evm_#{id}"}

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
      def pre_stop(_, state), do: state

      @impl EVM
      def on_terminate(config, state),
        do: Logger.debug("#{config.id}: Terminating... #{inspect(state, pretty: true)}")

      @impl EVM
      def handle_started(_config, _internal_state),
        do: :ignore

      @impl EVM
      def initial_accounts(%Config{db_path: db_path}, state),
        do: {:reply, load_accounts(db_path), state}

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

        %EVM.Process{
          id: id,
          network_id: network_id,
          coinbase: coinbase,
          accounts: accounts,
          gas_limit: gas_limit,
          rpc_url: "http://#{front_url()}:#{http_port}",
          ws_url: "ws://#{front_url()}:#{ws_port}"
        }
      end

      # Internal handler for evm actions
      defp handle_action(reply, %State{config: config} = state) do
        case reply do
          :ok ->
            {:noreply, state}

          :ignore ->
            {:noreply, state}

          {:ok, new_internal_state} ->
            {:noreply, %State{state | internal_state: new_internal_state}}

          {:reply, reply, new_internal_state} ->
            {:reply, reply, %State{state | internal_state: new_internal_state}}

          {:error, err} ->
            Logger.error(
              "#{get_in(state, [:config, :id])}: action failed with error: #{inspect(err)}"
            )

            # Notify status change
            Helper.notify_status(config.id, :failed)
            # Do we really need to stop ?
            {:stop, :error, %State{state | status: :failed}}
        end
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

      # Allow to override functions
      defoverridable handle_started: 2,
                     pre_stop: 2,
                     pick_ports: 2,
                     migrate_config: 1,
                     get_version: 0,
                     version: 0,
                     on_terminate: 2
    end
  end
end
