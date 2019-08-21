defmodule Staxx.Proxy.ExChain.FakeExChain do
  @behaviour Staxx.Proxy.ExChain

  use GenServer

  def start_link(_),
    do: GenServer.start_link(__MODULE__, %{chains: %{}, snapshots: %{}}, name: __MODULE__)

  @impl GenServer
  def init(state),
    do: {:ok, state}

  @impl GenServer
  def handle_call(:chains, _, %{chains: chains} = state),
    do: {:reply, chains, state}

  @impl GenServer
  def handle_call(:snapshots, _, %{snapshots: snapshots} = state),
    do: {:reply, snapshots, state}

  @impl GenServer
  def handle_call({:start, node, %{id: id} = config}, _, %{chains: chains} = state) do
    case Map.get(chains, id) do
      nil ->
        {:reply, {:ok, id},
         %{state | chains: Map.put(chains, id, %{status: :started, node: node, config: config})}}

      _res ->
        {:reply, {:error, :already_started}, state}
    end
  end

  @impl GenServer
  def handle_call({:start_existring, id, pid}, _, %{chains: chains} = state) do
    case Map.get(chains, id) do
      nil ->
        {:reply, {:error, :not_exist}, state}

      %{status: :stopped, config: config} = chain ->
        {:reply, {:ok, id},
         %{
           state
           | chains:
               Map.put(chains, id, %{
                 chain
                 | status: :started,
                   config: %{config | notify_pid: pid}
               })
         }}
    end
  end

  @impl GenServer
  def handle_call({:stop, id}, _, %{chains: chains} = state) do
    case Map.get(chains, id) do
      nil ->
        {:reply, {:error, :not_exist}, state}

      %{config: config} = chain ->
        if pid = Map.get(config, :notify_pid) do
          send(pid, %Chain.EVM.Notification{id: id, event: :stopped})
        end

        {:reply, :ok, %{state | chains: Map.put(chains, id, %{chain | status: :stopped})}}
    end
  end

  @impl GenServer
  def handle_call({:clean, id}, _, %{chains: chains} = state),
    do: {:reply, :ok, %{state | chains: Map.delete(chains, id)}}

  @impl true
  def child_spec() do
    [
      Staxx.Proxy.ExChain.FakeExChain
    ]
  end

  @impl true
  def unique_id(_node) do
    <<new_unique_id::big-integer-size(8)-unit(8)>> = :crypto.strong_rand_bytes(8)
    to_string(new_unique_id)
  end

  @impl true
  def chain_list(_node) do
    __MODULE__
    |> GenServer.call(:chains)
    |> Enum.map(fn {_, v} -> v end)
    |> Enum.to_list()
  end

  @impl true
  def start_existing(_node, id, pid),
    do: GenServer.call(__MODULE__, {:start_existring, id, pid})

  @impl true
  def start(node, config),
    do: GenServer.call(__MODULE__, {:start, node, config})

  @impl true
  def new_notify_pid(_node, _id, _pid), do: :ok

  @impl true
  def stop(_node, id),
    do: GenServer.call(__MODULE__, {:stop, id})

  @impl true
  def clean(_node, id),
    do: GenServer.call(__MODULE__, {:clean, id})

  @impl true
  def details(_node, id),
    do: GenServer.call(__MODULE__, {:details, id})

  @impl true
  def take_snapshot(_node, _id, _description \\ ""), do: :ok

  @impl true
  def revert_snapshot(_node, _id, _snapshot), do: :ok

  @impl true
  def load_snapshot(_node, _snapshot_id), do: :ok

  @impl true
  def snapshot_list(_node, _chain) do
    __MODULE__
    |> GenServer.call(:snapshots)
    |> Enum.map(fn {_, v} -> v end)
    |> Enum.to_list()
  end

  @impl true
  def get_snapshot(_node, _snapshot_id), do: :ok

  @impl true
  def upload_snapshot(_node, _snapshot_id, _chain_type, _description \\ ""), do: :ok

  @impl true
  def remove_snapshot(_node, _snapshot_id), do: :ok

  @impl true
  def write_external_data(_node, _id, _data), do: :ok

  @impl true
  def read_external_data(_node, _id), do: :ok

  @impl true
  def version(_node), do: "v 1.0.0"
end
