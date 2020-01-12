defmodule Staxx.Testchain.EVMTestCase do
  @moduledoc """
  Default test for every EVM.
  All EVMs (chains) have to pass this test
  """

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, async: true

      import Staxx.Testchain.Factory

      alias Staxx.Testchain
      alias Staxx.Testchain.Test.EventSubscriber
      alias Staxx.Testchain.Helper
      alias Staxx.Testchain.EVM
      alias Staxx.Testchain.EVM.{Config, Details}
      alias Staxx.EventStream.Notification
      alias Staxx.Testchain.SnapshotDetails
      alias Staxx.Testchain.SnapshotManager
      alias Staxx.Store.Models.Chain, as: ChainRecord
      alias Staxx.Store.Models.User, as: UserRecord

      @timeout unquote(opts)[:timeout] || Application.get_env(:testchain, :kill_timeout)
      @chain unquote(opts)[:chain]

      @moduletag :testchain
      @moduletag @chain

      @doc """
      Checks if pid receive status notification
      """
      @spec assert_receive_status(Testchain.evnm_id(), Testchain.EVM.status()) :: term
      def assert_receive_status(id, status) do
        assert_receive %Notification{
                         id: ^id,
                         event: :status_changed,
                         data: %{status: ^status}
                       },
                       Application.fetch_env!(:ex_unit, :assert_receive_timeout),
                       "#{id}: Failed to receive status #{status}"
      end

      @doc """
      Starts new chain and validates that it started correctly and sent initial events
      like `:initialized` and `:active`
      """
      @spec start_chain(Config.t()) :: {:ok, pid, Config.t()}
      def start_chain(config \\ nil) do
        # Subscribing to events
        EventSubscriber.subscribe(self())

        %Config{id: id} =
          config =
          config
          |> case do
            nil ->
              build_evm_config(@chain)

            _ ->
              config
          end

        assert %{start: {module, _, _}} = EVM.child_spec(config)

        Process.flag(:trap_exit, true)
        assert {:ok, pid} = module.start_link(config)
        assert Process.alive?(pid)

        # Check for :initializing event
        assert_receive_status(id, :initializing)
        assert_receive_status(id, :active)

        {:ok, pid, config}
      end

      @doc """
      Validates chain details to be correct related to given config
      """
      @spec assert_details(Config.t(), Details.t()) :: term
      def assert_details(%Config{id: id} = config, %Details{} = details) do
        # Check accounts created correctly
        assert is_list(details.accounts)
        assert config.accounts == length(details.accounts)

        # Check initial configs
        assert id == details.id
        assert config.network_id == details.network_id

        # Check URL's
        assert details.rpc_url =~ "http"
        assert details.ws_url =~ "ws"
      end

      @doc """
      Stops EVM and validates that all stop events are fired
      """
      @spec stop_chain(Testchain.evm_id(), pid) :: term
      def stop_chain(id, pid) do
        # Terminating
        assert :ok = GenServer.stop(pid)

        assert_receive_status(id, :terminating)
        assert_receive_status(id, :terminated)

        assert_receive {:EXIT, ^pid, _}
      end

      # Test setup process
      setup_all do
        # Setup real Docker adapter. Otherwise test does not make sense.
        # It will be rewritten by test_helper.exs file in this app !
        Application.put_env(:docker, :adapter, Staxx.Docker.Adapter.DockerD)

        :ok
      end

      test "#{@chain} to start and fire correct events and cleanup after stop with `clean_on_stop: true`" do
        {:ok, pid, %Config{id: id} = config} =
          @chain
          |> build_evm_config()
          |> Map.put(:clean_on_stop, true)
          |> start_chain()

        # Check started and details
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = details}
        assert_receive_status(id, :ready)

        assert_details(config, details)

        # Validate data files exist
        assert id
               |> Testchain.evm_db_path()
               |> File.exists?()

        # validate chain details are in DB
        chain_record = ChainRecord.get(id)
        assert chain_record.chain_id == id
        assert chain_record.title == config.description
        assert chain_record.status == "ready"
        assert chain_record.node_type == Atom.to_string(@chain)

        # Validating config
        assert is_map(chain_record.config)
        assert config.accounts == Map.get(chain_record.config, "accounts")
        assert config.block_mine_time == Map.get(chain_record.config, "block_mine_time")
        assert config.clean_on_stop == Map.get(chain_record.config, "clean_on_stop")
        assert config.deploy_ref == Map.get(chain_record.config, "deploy_ref")
        assert config.deploy_step_id == Map.get(chain_record.config, "deploy_step_id")
        assert config.gas_limit == Map.get(chain_record.config, "gas_limit")
        assert config.network_id == Map.get(chain_record.config, "network_id")
        assert Atom.to_string(config.type) == Map.get(chain_record.config, "type")

        # Validating chain details
        assert is_map(chain_record.details)

        loaded_accounts = chain_record.details |> Map.get("accounts", [])

        assert length(details.accounts) == length(loaded_accounts)

        assert details.accounts |> List.first() |> Map.get(:address) ==
                 loaded_accounts |> List.first() |> Map.get("address")

        assert details.accounts |> List.first() |> Map.get(:balance) ==
                 loaded_accounts |> List.first() |> Map.get("balance")

        assert details.accounts |> List.first() |> Map.get(:priv_key) ==
                 loaded_accounts |> List.first() |> Map.get("priv_key")

        assert details.coinbase == Map.get(chain_record.details, "coinbase")
        assert details.gas_limit == Map.get(chain_record.details, "gas_limit")
        assert details.id == Map.get(chain_record.details, "id")
        assert details.network_id == Map.get(chain_record.details, "network_id")
        assert details.rpc_url == Map.get(chain_record.details, "rpc_url")
        assert details.ws_url == Map.get(chain_record.details, "ws_url")

        stop_chain(id, pid)

        # Validate chain cleaned everything after stop
        assert nil == ChainRecord.get(id)

        # Validate data files deleted
        refute id
               |> Testchain.evm_db_path()
               |> File.exists?()
      end

      test "#{@chain} should correctly work with `clean_on_stop: false`" do
        {:ok, pid, %Config{id: id} = config} =
          @chain
          |> build_evm_config()
          |> Map.put(:clean_on_stop, false)
          |> start_chain()

        # Check started and details
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = details}
        assert_receive_status(id, :ready)

        assert_details(config, details)

        # Validate data files exist
        assert id
               |> Testchain.evm_db_path()
               |> File.exists?()

        # validate chain details are in DB
        assert %ChainRecord{chain_id: ^id} = ChainRecord.get(id)

        # Stopping chain
        stop_chain(id, pid)

        # Validate data files still exist
        assert id
               |> Testchain.evm_db_path()
               |> File.exists?()

        # validate chain details are still in DB
        assert %ChainRecord{chain_id: ^id} = ChainRecord.get(id)

        # Loading config
        assert {:ok, %Config{id: ^id, existing: true} = new_config} =
                 Helper.load_exitsing_chain_config(id)

        # Starting existing chain again
        {:ok, pid, %Config{id: ^id} = config} =
          new_config
          |> start_chain()

        # Check started and details
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = details}
        assert_receive_status(id, :ready)

        assert_details(config, details)

        # Validate data files exist
        assert id
               |> Testchain.evm_db_path()
               |> File.exists?()

        # validate chain details are in DB
        assert %ChainRecord{chain_id: ^id} = ChainRecord.get(id)

        # Stopping chain
        stop_chain(id, pid)

        # Remove chain data
        assert :ok = EVM.clean(id)
      end

      test "#{@chain} to makes/restores snapshot" do
        {:ok, pid, %Config{id: id} = config} = start_chain()

        # Check started and details
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = details}
        assert_receive_status(id, :ready)

        assert_details(config, details)

        assert :ok = Testchain.take_snapshot(id)

        assert_receive_status(id, :snapshot_taking)

        assert_receive %Notification{
          id: ^id,
          event: :snapshot_taken,
          data: %SnapshotDetails{} = snapshot
        }

        assert snapshot.chain == @chain
        # snapshot id should not be same as chain_id
        refute snapshot.id == id
        assert snapshot.path =~ snapshot.id

        # validate snapshot existence
        assert SnapshotManager.exists?(snapshot)
        assert snapshot == SnapshotManager.by_id(snapshot.id)

        # Should start after taking snapshot
        assert_receive_status(id, :active)
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = new_details}
        assert_receive_status(id, :ready)

        # Chain details should not change
        assert details == new_details

        # Reverting snapshot
        assert :ok = Testchain.revert_snapshot(id, snapshot.id)

        assert_receive_status(id, :snapshot_reverting)

        assert_receive %Notification{
          id: ^id,
          event: :snapshot_reverted,
          data: %SnapshotDetails{} = reverted_snapshot
        }

        # Should start after reverting snapshot
        assert_receive_status(id, :active)
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = new_details}
        assert_receive_status(id, :ready)

        # Stopping chain and then validating details
        stop_chain(id, pid)

        # Validate restored snapshot was correct one
        assert reverted_snapshot == snapshot

        # Removing snapshot
        assert :ok = SnapshotManager.remove(snapshot.id)
        refute SnapshotManager.exists?(snapshot)
      end

      test "#{@chain} to be able to start using snapshot_id" do
        {:ok, pid, %Config{id: id} = config} = start_chain()

        # Check started and details
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = details}
        assert_receive_status(id, :ready)

        assert_details(config, details)

        assert :ok = Testchain.take_snapshot(id)

        assert_receive_status(id, :snapshot_taking)

        assert_receive %Notification{
          id: ^id,
          event: :snapshot_taken,
          data: %SnapshotDetails{} = snapshot
        }

        assert snapshot.chain == @chain
        # snapshot id should not be same as chain_id
        refute snapshot.id == id
        assert snapshot.path =~ snapshot.id

        # validate snapshot existence
        assert SnapshotManager.exists?(snapshot)
        assert snapshot == SnapshotManager.by_id(snapshot.id)

        # Should start after taking snapshot
        assert_receive_status(id, :active)
        assert_receive_status(id, :ready)

        # Stopping chain to start new with snapshot_id
        stop_chain(id, pid)

        {:ok, pid, %Config{id: id} = config} =
          @chain
          |> build_evm_config()
          |> Map.put(:clean_on_stop, true)
          |> Map.put(:snapshot_id, snapshot.id)
          |> start_chain()

        # Check started and details
        assert_receive %Notification{id: ^id, event: :started, data: %Details{} = new_details}
        assert_receive_status(id, :ready)

        # Check chain details that should be similar
        assert details.accounts == new_details.accounts
        assert details.network_id == new_details.network_id
        assert details.coinbase == new_details.coinbase
        assert details.gas_limit == new_details.gas_limit

        # Check details that should change
        refute details.id == new_details.id
        refute details.rpc_url == new_details.rpc_url
        refute details.ws_url == new_details.ws_url

        # Stopping chain to start new with snapshot_id
        stop_chain(id, pid)

        # Removing snapshot
        assert :ok = SnapshotManager.remove(snapshot.id)
        refute SnapshotManager.exists?(snapshot)
      end
    end
  end
end
