defmodule Staxx.Proxy.ExChain.FakeExChain do
  @behaviour Staxx.Proxy.ExChain

  use GenServer
  alias Staxx.Proxy.ExChain

  def start_link(_),
    do: GenServer.start_link(__MODULE__, %{chains: %{}, snapshots: %{}}, name: __MODULE__)

  def init(state),
    do: {:ok, state}

  def handle_call(:chains, _, %{chains: chains} = state),
    do: {:reply, chains, state}

  def handle_call(:snapshots, _, %{snapshots: snapshots} = state),
    do: {:reply, snapshots, state}

  def handle_call({:start, node, %{id: id} = config}, _, %{chains: chains} = state) do
    case Map.get(chains, id) do
      nil ->
        {:reply, {:ok, id},
         %{state | chains: Map.put(chains, id, %{status: :started, node: node, config: config})}}

      res ->
        {:reply, {:error, :already_started}, state}
    end
  end

  def handle_call({:start_existring, id}, _, %{chains: chains} = state) do
    case Map.get(chains, id) do
      nil ->
        {:reply, {:error, :not_exist}, state}

      %{status: :stopped} = chain ->
        {:reply, {:ok, id}, %{state | chains: Map.put(chains, id, %{chain | status: :started})}}
    end
  end

  def handle_call({:stop, id}, _, %{chains: chains} = state) do
    case Map.get(chains, id) do
      nil ->
        {:reply, {:error, :not_exist}, state}

      chain ->
        {:reply, :ok, %{state | chains: Map.put(chains, id, %{chain | status: :stopped})}}
    end
  end

  def handle_call({:clean, id}, _, %{chains: chains} = state),
    do: {:reply, :ok, %{state | chains: Map.delete(chains, id)}}

  @impl true
  def unique_id(node) do
    <<new_unique_id::big-integer-size(8)-unit(8)>> = :crypto.strong_rand_bytes(8)
    to_string(new_unique_id)
  end

  @impl true
  def chain_list(node) do
    __MODULE__
    |> GenServer.call(:chains)
    |> Enum.map(fn {k, v} -> v end)
    |> Enum.to_list()
  end

  @impl true
  def start_existing(node, id, pid),
    do: GenServer.call(__MODULE__, {:start_existring, id})

  @impl true
  def start(node, config),
    do: GenServer.call(__MODULE__, {:start, node, config})

  @impl true
  def new_notify_pid(node, id, pid), do: :ok

  @impl true
  def stop(node, id),
    do: GenServer.call(__MODULE__, {:stop, id})

  @impl true
  def clean(node, id),
    do: GenServer.call(__MODULE__, {:clean, id})

  @impl true
  def details(node, id),
    do: GenServer.call(__MODULE__, {:details, id})

  @impl true
  def take_snapshot(node, id, description \\ ""), do: :ok

  @impl true
  def revert_snapshot(node, id, snapshot), do: :ok

  @impl true
  def load_snapshot(node, snapshot_id), do: :ok

  @impl true
  def snapshot_list(node, chain) do
    __MODULE__
    |> GenServer.call(:snapshots)
    |> Enum.map(fn {k, v} -> v end)
    |> Enum.to_list()
  end

  @impl true
  def get_snapshot(node, snapshot_id), do: :ok

  @impl true
  def upload_snapshot(node, snapshot_id, chain_type, description \\ ""), do: :ok

  @impl true
  def remove_snapshot(node, snapshot_id), do: :ok

  @impl true
  def write_external_data(node, id, data), do: :ok

  @impl true
  def read_external_data(node, id), do: :ok

  @impl true
  def version(node), do: "v 1.0.0"
end
