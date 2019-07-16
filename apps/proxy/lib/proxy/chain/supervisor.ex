defmodule Proxy.Chain.Supervisor do
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
  @spec start_chain(map() | binary, :new | :existing) ::
          DynamicSupervisor.on_start_child()
  def start_chain(config_or_id, action),
    do: DynamicSupervisor.start_child(__MODULE__, {Proxy.Chain, {action, config_or_id}})
end
