defmodule Staxx.Docker.PortMapperTest do
  use ExUnit.Case
  alias Staxx.Docker.PortMapper

  setup_all do
    PortMapper.start_link([])
    :ok
  end

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
