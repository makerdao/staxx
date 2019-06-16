defmodule Stacks.Stack.ConfigTest do
  use ExUnit.Case

  alias Stacks.Stack.Config

  test "has_image?/2 should check if image exist" do
    config = %Config{containers: %{vdb: %{image: "test"}}}

    assert Config.has_image?(config, "test")
    refute Config.has_image?(config, "test-other")
  end
end
