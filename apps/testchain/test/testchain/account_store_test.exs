defmodule Staxx.Testchain.AccountStoreTest do
  use ExUnit.Case

  @moduletag :testchain
  @moduletag :account_store

  alias Staxx.Testchain
  alias Staxx.Testchain.AccountStore
  alias Staxx.Testchain.EVM.Account

  test "should create account in account store" do
    db_path = Testchain.unique_id() |> Testchain.evm_db_path()
    assert AccountStore.exists?(db_path) == false

    File.mkdir!(db_path)

    accounts = Enum.map(0..2, fn _ -> Account.new() end)
    assert AccountStore.store(db_path, accounts) == :ok
    assert AccountStore.exists?(db_path) == true

    {:ok, [%Account{} | _] = loaded_accounts} = AccountStore.load(db_path)
    assert length(loaded_accounts) == 3

    File.rm_rf!(db_path)
    assert AccountStore.exists?(db_path) == false
  end
end
