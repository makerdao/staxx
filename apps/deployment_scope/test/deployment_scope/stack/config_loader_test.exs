defmodule Staxx.DeploymentScope.Stack.ConfigLoaderTest do
  use ExUnit.Case

  @moduledoc """
  Please see file `priv/test/stacks/test/stack.json` for list of available names/containers
  """

  alias Staxx.DeploymentScope.Stack.Config
  alias Staxx.DeploymentScope.Stack.ConfigLoader

  @stack_name "test"
  @allowed_container "some/container"

  test "get/0 should return all configs" do
    assert is_map(ConfigLoader.get())

    %Config{name: @stack_name} =
      ConfigLoader.get()
      |> Map.get(@stack_name)
  end

  test "get/1 should pick only given stack configs or nil" do
    %Config{name: @stack_name} = ConfigLoader.get(@stack_name)
    assert nil == ConfigLoader.get(Faker.String.base64())
  end

  test "has_image?/2 return correct values" do
    assert ConfigLoader.has_image?(@stack_name, @allowed_container)
    refute ConfigLoader.has_image?(@stack_name, Faker.String.base64())
    refute ConfigLoader.has_image?(Faker.String.base64(), @allowed_container)
  end
end
