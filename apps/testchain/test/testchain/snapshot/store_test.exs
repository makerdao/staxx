defmodule Staxx.Testchain.SnapshotStoreTest do
  use Staxx.Testchain.TestCase

  alias Staxx.Testchain.SnapshotDetails
  alias Staxx.Testchain.SnapshotStore

  @moduletag :testchain

  describe "Snapshots store tests :: " do
    test "should succesfully store snapshot" do
      assert :ok == SnapshotStore.store(build_snapshot_details())
    end

    test "should return snapshot by id" do
      %{id: id, description: description, path: path} = snapshot = build_snapshot_details()
      SnapshotStore.store(snapshot)

      assert %SnapshotDetails{id: id1, description: description1, path: path1} =
               SnapshotStore.by_id(id)

      assert id == id1
      assert description == description1
      assert path == path1
    end

    test "should return nil for unexisted id" do
      assert nil == SnapshotStore.by_id("some_unexisted_id")
    end

    test "should return snapshots by chain type" do
      snapshot_ganache1 = build_snapshot_details()
      snapshot_ganache2 = build_snapshot_details()
      snapshot_geth = build_snapshot_details(:geth)

      SnapshotStore.store(snapshot_ganache1)
      SnapshotStore.store(snapshot_ganache2)
      SnapshotStore.store(snapshot_geth)

      assert [%SnapshotDetails{chain: :ganache}, %SnapshotDetails{chain: :ganache}] =
               SnapshotStore.by_chain(:ganache)

      assert [%SnapshotDetails{chain: :geth}] = SnapshotStore.by_chain(:geth)
    end

    test "should remove snapshot" do
      %{id: id} = snapshot = build_snapshot_details()
      SnapshotStore.store(snapshot)
      SnapshotStore.remove(id)
      assert nil == SnapshotStore.by_id(id)
    end
  end
end
