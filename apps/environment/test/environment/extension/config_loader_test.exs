defmodule Staxx.Environment.Extension.ConfigLoaderTest do
  use ExUnit.Case

  @moduledoc """
  Please see file `priv/test/extensions/test/extension.json` for list of available names/containers
  """

  alias Staxx.Environment.Extension.Config
  alias Staxx.Environment.Extension.ConfigLoader

  @extension_name "test"
  @allowed_container "some/container"

  test "get/0 should return all configs" do
    assert is_map(ConfigLoader.get())

    %Config{name: @extension_name} =
      ConfigLoader.get()
      |> Map.get(@extension_name)
  end

  test "get/1 should pick only given extension configs or nil" do
    %Config{name: @extension_name} = ConfigLoader.get(@extension_name)
    assert nil == ConfigLoader.get(Faker.String.base64())
  end

  test "has_image?/2 return correct values" do
    assert ConfigLoader.has_image?(@extension_name, @allowed_container)
    refute ConfigLoader.has_image?(@extension_name, Faker.String.base64())
    refute ConfigLoader.has_image?(Faker.String.base64(), @allowed_container)
  end
end
