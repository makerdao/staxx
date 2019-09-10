defmodule Staxx.ExChainTest do
  use ExUnit.Case
  doctest Staxx.ExChain

  alias Staxx.ExChain
  alias Staxx.ExChain.EVM.Config

  test "start() fail with non existing chain" do
    {:error, :unsuported_evm_type} =
      %Config{type: :non_existing}
      |> ExChain.start()
  end

  test "unique_id() to get uniq numbers" do
    refute ExChain.unique_id() == ExChain.unique_id()
  end

  test "version() to get versions" do
    assert ExChain.version() =~ "version"
  end
end
