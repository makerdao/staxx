defmodule Staxx.Testchain.EVMTestCase do
  @moduledoc """
  Default test for every EVM.
  All EVMs (chains) have to pass this test
  """

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, async: true

      import Staxx.Testchain.Factory

      alias Staxx.Testchain.Test.EventSubscriber
      alias Staxx.Testchain.EVM
      alias Staxx.EventStream.Notification

      @moduletag :testchain

      @timeout unquote(opts)[:timeout] || Application.get_env(:testchain, :kill_timeout)
      @chain unquote(opts)[:chain]

      setup_all do
        on_exit(fn ->
          nil
        end)

        {:ok, %{}}
      end

      test "#{@chain} to start" do
        # Subscribing to events
        EventSubscriber.subscribe(self())

        %{id: id} = config = build_evm_config()
        assert %{start: {module, _, _}} = EVM.child_spec(config)

        assert {:ok, pid} = module.start_link(config)
        assert Process.alive?(pid)

        # Check for :initializing event
        assert_receive %Notification{
          id: ^id,
          event: :status_changed,
          data: %{status: :initializing}
        }

        # TODO: check evm and it's liveness probing
        assert_receive %Notification{id: ^id}, 5000
      end
    end
  end
end
