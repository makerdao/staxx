defmodule Staxx.Store.StoreTestCase do
  @moduledoc """
  Test case for every Store Adapter.
  """
  defmacro __using__(opts) do
    quote do
      import Staxx.Store.Factory
      use ExUnit.Case, async: true

      @adapter unquote(opts)[:adapter]

      describe "Snapshots store tests with adapter #{@adapter} :: " do
        test "should succesfully store snapshot" do
          assert :ok == @adapter.store(build_snapshot_details())
        end

        test "should return snapshot by id" do
          %{id: id, description: description, path: path} = snapshot = build_snapshot_details()
          assert :ok == @adapter.store(snapshot)

          assert %{id: id1, description: description1, path: path1} =
                   found_snapshot = @adapter.by_id(id)

          assert id == id1
          assert description == description1
          assert path == path1
        end

        test "should return nil for unexisted id" do
          assert nil == @adapter.by_id(Faker.UUID.v4())
        end

        test "should return snapshots by chain type" do
          assert :ok = build_snapshot_details() |> @adapter.store()
          assert :ok = build_snapshot_details() |> @adapter.store()
          assert :ok = build_snapshot_details(:geth) |> @adapter.store()
          assert [%{chain: :ganache}, %{chain: :ganache}] = @adapter.by_chain(:ganache)
          assert [%{chain: :geth}] = @adapter.by_chain(:geth)
        end

        test "should remove snapshot" do
          %{id: id} = snapshot = build_snapshot_details()
          @adapter.store(snapshot)
          @adapter.remove(id)
          assert nil == @adapter.by_id(id)
        end
      end
    end
  end
end
