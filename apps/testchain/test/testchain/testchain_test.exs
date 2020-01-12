defmodule Staxx.TestchainTest do
  use ExUnit.Case
  doctest Staxx.Testchain

  alias Staxx.Testchain
  alias Staxx.Utils

  @moduletag :testchain

  test "unique_id/0 generates uniq ids" do
    assert Testchain.unique_id() != Testchain.unique_id()
  end

  test "evm_db_path/1 generate path" do
    id = Testchain.unique_id()
    path = Testchain.evm_db_path(id)
    assert path =~ id
  end

  test "version/0 return version" do
    assert Testchain.version() =~ "version"
  end

  describe "external_data tests" do
    test "write_external_data/2 fails if no db path exist" do
      # No db path exist
      refute :ok ==
               Testchain.unique_id()
               |> Testchain.write_external_data(%{})
    end

    test "write_external_data/2 writes data to file" do
      id = Testchain.unique_id()

      assert :ok =
               id
               |> Testchain.evm_db_path()
               |> Utils.mkdir_p()

      data = %{"test" => Faker.String.base64()}

      assert :ok == Testchain.write_external_data(id, data)

      assert {:ok, loaded_data} = Testchain.read_external_data(id)

      assert Map.get(loaded_data, "test", Faker.String.base64()) == Map.get(data, "test")

      assert {:ok, nil} =
               Testchain.unique_id()
               |> Testchain.read_external_data()
    end
  end
end
