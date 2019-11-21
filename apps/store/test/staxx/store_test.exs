defmodule Staxx.StoreTest do
  use ExUnit.Case
  doctest Staxx.Store

  test "greets the world" do
    assert Staxx.Store.hello() == :world
  end
end
