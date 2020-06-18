defmodule Staxx.Store.Testchain.SnapshotsStore do
  @moduledoc """
  Module for storing Staxx.Testchain.SnapshotDetails.
  Has two implementations: to store in DETS or in Postgresql.
  Specific adapter has to be configured in configs by ":store, :snapshots_store_adapter" key.
  Contains specification of behaviour for adapters.
  """

  @doc """
  Child specs for adapter.
  Return Supervisor.child_spec() if adapter should start on application start.
  Return empty list if shouldn't.
  """
  @callback child_spec() :: Supervisor.child_spec()

  @doc """
  Stores given snapshot details map in to a storage.
  Returns :ok in success case.
  Returns {:error, term()} in fail case.
  """
  @callback store(map()) :: :ok | {:error, term()}

  @doc """
  Returns snapshot details map by given id.
  Returns nil if snapshot detail is not found in storage.
  """
  @callback by_id(binary) :: map() | nil

  @doc """
  Returns snapshot details map list with given EVM type.
  Returns empty list if snapshot details are not found in storage.
  Available chain types are:
   - "ganache"
   - "geth"
   - "geth_vdb"
   - "parity"
   See Staxx.Testchain module for more information.
  """
  @callback by_chain(binary) :: [map()]

  @doc """
  Removes snapshot by given id.
  Always returns :ok.
  """
  @callback remove(binary) :: :ok

  @doc """
  Removes all snapshots.
  Always returns :ok.
  """
  @callback remove_all() :: :ok

  @doc """
  Calls child_spec function of configured adapter.
  """
  @spec child_spec() :: Supervisor.child_spec()
  def child_spec(), do: adapter().child_spec()

  @doc """
  Applies init function of Staxx.Store.Testchain.Adapter behaviour implemented in configured adapter to initialization.
  Returns :ok
  """
  @spec init_adapter() :: :ok
  def init_adapter(), do: adapter().init_adapter()

  @doc """
  Applies release function Staxx.Store.Testchain.Adapter behaviourimplemented in configured adapter to before terminating clean up.
  Returns :ok
  """
  @spec release() :: :ok
  def release(), do: adapter().release()

  @doc """
  Applies :store function from Staxx.Store.Testchain.Adapter behaviour in configured adapter to store snapshot details.
  Returns :ok if snapshot stored successfully.
  Returns {:error, term()} in error case.
  """
  @spec store(map()) :: :ok | {:error, term()}
  def store(snapshot), do: adapter().store(snapshot)

  @doc """
  Applies :by_id function from Staxx.Store.Testchain.Adapter behaviour in configured adapter to get snapshot by id.
  Returns map with snapshot details.
  Returns nil if snapshot with given id doesn't exist in storage.
  """
  @spec by_id(binary) :: map() | nil
  def by_id(id), do: adapter().by_id(id)

  @doc """
  Applies :by_chain function from Staxx.Store.Testchain.Adapter behaviour in configured adapter to get snapshot by chain type.
  Returns snapshot details map list with given chain type.
  Returns empty list if snapshot details are not found in storage.
  """
  @spec by_chain(binary | atom()) :: [map()]
  def by_chain(chain), do: adapter().by_chain(chain)

  @doc """
  Applies :remove function from Staxx.Store.Testchain.Adapter behaviour in configured adapter to remove snapshot by id.
  Always returns :ok.
  """
  def remove(id), do: adapter().remove(id)

  @doc """
  Applies :remove_all function from Staxx.Store.Testchain.Adapter behaviour in configured adapter to remove all snapshots.
  Always returns :ok.
  """
  @spec remove_all() :: :ok
  def remove_all(), do: adapter().remove_all()

  @doc """
  Returns adapter defined in configs.
  Raises ArgumentError if ':snapshots_store_adapter' is not configured.
  """
  def adapter() do
    Application.get_env(
      :store,
      :snapshots_store_adapter
    ) || raise ArgumentError, "`:snapshots_store_adapter` required to be configured"
  end
end
