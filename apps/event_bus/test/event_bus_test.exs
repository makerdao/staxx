defmodule EventBusTest do
  use ExUnit.Case
  doctest EventBus

  test "greets the world" do
    assert EventBus.hello() == :world
  end
end
