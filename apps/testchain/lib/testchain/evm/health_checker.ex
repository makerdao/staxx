defmodule Staxx.Testchain.EVM.HealthChecker do
  @moduledoc """
  Process that will check health of EVM periodically.
  GenServer will have some timeout for health checks but for some special cases
  like take/revert snapshot it might be paused.
  """
  use GenServer

  require Logger

  alias Staxx.Testchain

  @typedoc "HealthChecker status"
  @type status :: :active | :paused

  @typedoc "Checker state"
  @type state :: {Testchain.evm_id(), status()}

  # Health check timeout. 
  @timeout Application.get_env(:testchain, :health_check_timeout, 5_000)

  @doc """
  Return `via` tuple spec for GenServer registration
  """
  @spec via(Testchain.evm_id()) :: {:global, binary}
  def via(id),
    do: {:global, "testchain_health_checker_#{id}"}

  @doc """
  Starts new Health Checker process for testchain with given `id`
  """
  @spec start_link(Testchain.evm_id()) :: GenServer.on_start()
  def start_link(id),
    do: GenServer.start_link(__MODULE__, {id, :active}, name: via(id))

  @doc false
  @spec init(state()) :: {:ok, state(), :hibernate}
  def init({id, :active}),
    do: {:ok, {id, :active}, set_timeout()}

  @doc false
  def handle_info(:check, {id, :active}) do
    case do_health_check(id) do
      :ok ->
        {:noreply, {id, :active}, set_timeout()}

      err ->
        Logger.error(fn -> "#{id}: Health Check failed: #{inspect(err, pretty: true)}" end)
        {:noreply, {id, :active}, set_timeout()}
    end
  end

  def handle_info(:check, {id, _}) do
    Logger.debug(fn -> "#{id}: Health check is not active. Skipping..." end)
    {:noreply, {id, :active}, set_timeout()}
  end

  defp do_health_check(_id) do
    # TODO: pass http_port and make real check

    # case JsonRpc.eth_coinbase("http://localhost:#{http_port}") do
    #   {:ok, <<"0x", _::binary>>} ->
    #     :ok

    #   _ ->
    #     Logger.error(fn -> "#{id}: Failed to check health for EVM" end)
    #     :ok
    # end
    :ok
  end

  # Will set timer with next check message using `Process.send_after/4`
  # And will return hybernate instruction for GenServer
  defp set_timeout() do
    Process.send_after(self(), :check, @timeout)
    :hibernate
  end
end
