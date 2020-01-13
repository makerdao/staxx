defmodule Staxx.Docker.PortMapperTest do
  use ExUnit.Case
  alias Staxx.Docker.PortMapper

  @moduletag :docker

  test "should get a new port" do
    port = PortMapper.random()
    assert is_integer(port)
    assert PortMapper.reserved?(port)
    assert :ok = PortMapper.terminate(port)

    port = PortMapper.random()
    assert is_integer(port)
    assert PortMapper.reserved?(port)
    assert :ok = PortMapper.free(port)
  end
end
