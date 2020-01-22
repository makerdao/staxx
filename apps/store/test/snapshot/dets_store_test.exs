defmodule Staxx.Store.DETSTest do
  use Staxx.Store.StoreTestCase, adapter: Staxx.Store.Testchain.Adapters.DETS
  alias Staxx.Store.Testchain.Adapters.DETS

  # Clean snapshots table before each test
  setup do
    :ok = DETS.clear_snapshots_table()
  end
end
