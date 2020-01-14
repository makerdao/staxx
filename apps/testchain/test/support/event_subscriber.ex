defmodule Staxx.Testchain.Test.EventSubscriber do
  @moduledoc """
  Helper module for handling evens from EventStore
  """
  use GenServer

  alias Staxx.EventStream

  @doc false
  def start_link(),
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def init(nil) do
    # Subscribe for everything and all chains
    EventStream.subscribe({__MODULE__, [".*"]})

    {:ok, []}
  end

  @doc false
  def terminate(_reason, _) do
    # Unsubscribe from all events
    EventStream.unsubscribe(__MODULE__)
    :ok
  end

  @doc false
  def handle_cast({:subscribe, pid}, state) do
    state
    |> Enum.member?(pid)
    |> case do
      true ->
        {:noreply, state}

      false ->
        Process.monitor(pid)
        {:noreply, state ++ [pid]}
    end
  end

  @doc false
  def handle_cast({:event, {topic, id} = event_shadow}, state) do
    event_shadow
    |> EventBus.fetch_event()
    |> case do
      %{data: data} ->
        state
        |> Enum.each(&send(&1, data))

      _ ->
        :ok
    end

    # all versions
    EventBus.mark_as_completed({__MODULE__, topic, id})
    {:noreply, state}
  end

  @doc false
  def handle_info({:DOWN, ref, :process, pid, _}, state) do
    Process.demonitor(ref)

    state
    |> Enum.member?(pid)
    |> case do
      false ->
        {:noreply, state}

      true ->
        {:noreply, List.delete(state, pid)}
    end
  end

  # if your subscriber does not have a config
  def process(event_shadow),
    do: GenServer.cast(__MODULE__, {:event, event_shadow})

  @doc """
  Subscribe process to events
  """
  @spec subscribe(pid) :: :ok
  def subscribe(pid),
    do: GenServer.cast(__MODULE__, {:subscribe, pid})
end
