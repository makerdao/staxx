defmodule Staxx.Instance.Test.TestchainSupervisorMock do
  @moduledoc """
  Mock Testchain supervisor that will start but wouldn't start actual EVM or containers
  """

  use Supervisor

  require Logger

  alias Staxx.Testchain

  @doc false
  def child_spec({id, _} = params) do
    %{
      id: "testchain_supervisor_#{id}",
      start: {__MODULE__, :start_link, [params]},
      restart: :temporary,
      type: :supervisor
    }
  end

  @doc """
  Starts new supervision tree for testchain (EVM + deployment + helpers)
  """
  def start_link({id, _config_of_id} = params),
    do: Supervisor.start_link(__MODULE__, params, name: via(id))

  @impl true
  def init({_id, _chain_config}) do
    children = []

    opts = [strategy: :rest_for_one]
    Supervisor.init(children, opts)
  end

  @doc """
  Stops supervisor with all it's shildren
  """
  @spec stop(Testchain.evm_id()) :: :ok
  def stop(id) do
    id
    |> via()
    |> Supervisor.stop({:shutdown, id})
  end

  defp via(id),
    # do: {:via, Registry, {EVMRegistry, "supervisor_#{id}"}}
    do: {:global, "testchain_supervisor_#{id}"}
end
