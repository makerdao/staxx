defmodule Staxx.Testchain.EVMTest do
  use ExUnit.Case

  import Staxx.Testchain.Factory

  alias Staxx.Testchain
  alias Staxx.Testchain.EVM
  alias Staxx.Store.Models.Chain, as: ChainRecord
  alias Staxx.Utils

  @moduletag :testchain

  test "child_spec/1 return correct specs for chains" do
    assert {:error, _} =
             :geth
             |> build_evm_config()
             |> Map.put(:id, nil)
             |> EVM.child_spec()

    # Geth check
    config = build_evm_config()

    assert %{start: {module, :start_link, [param]}} =
             config
             |> EVM.child_spec()

    assert module == EVM.Implementation.Geth
    assert config == param

    # Ganache check
    config = Map.put(config, :type, :ganache)

    assert %{start: {module, :start_link, [param]}} =
             config
             |> EVM.child_spec()

    assert module == EVM.Implementation.Ganache
    assert config == param

    # wrong check
    config = Map.put(config, :type, :random)

    assert {:error, :unsuported_evm_type} =
             config
             |> EVM.child_spec()
  end

  test "clean/1 remove everything from path && db" do
    id = Testchain.unique_id()
    db_path = Testchain.evm_db_path(id)

    assert :ok = Utils.mkdir_p(db_path)
    assert File.exists?(db_path)

    assert {:ok, %ChainRecord{id: ^id}} = ChainRecord.create(%{id: id, node_type: "geth"})

    assert :ok = EVM.clean(id)
    refute File.exists?(db_path)

    assert id
           |> ChainRecord.get()
           |> is_nil()
  end

  test "clean_on_stop/1 should cleanup everything if `clean_on_stop: true`" do
    id = Testchain.unique_id()
    db_path = Testchain.evm_db_path(id)

    assert :ok = Utils.mkdir_p(db_path)

    config =
      build_evm_config()
      |> Map.put(:id, id)
      |> Map.put(:clean_on_stop, false)

    # Not removed
    assert :ok = EVM.clean_on_stop(config)
    assert File.exists?(db_path)

    assert :ok =
             config
             |> Map.put(:clean_on_stop, true)
             |> EVM.clean_on_stop()

    refute File.exists?(db_path)
  end
end
