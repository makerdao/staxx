defmodule Stacks.WatcherSupervisor do
  @moduledoc """
  Supervisor that will watch all chains running
  """

  # Automatically defines child_spec/1
  use DynamicSupervisor

  @doc false
  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start new **supervised** chain process

  Start process will receive configuration or chain id.
  If chain id passed system will try to start already existing chain in system
  and no other actions will be made.
  """
  @spec start_watcher(binary) :: DynamicSupervisor.on_start_child()
  def start_watcher(id),
    do: DynamicSupervisor.start_child(__MODULE__, {Stacks.Watcher, id})
end
