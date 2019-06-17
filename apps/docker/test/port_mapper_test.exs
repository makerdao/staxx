defmodule Docker.PortMapperTest do
  use ExUnit.Case
  alias Docker.PortMapper

  setup_all do
    PortMapper.start_link([])
    :ok
  end

  test "should get a new port" do
    port = PortMapper.random()
    assert is_integer(port)

    assert :ok = PortMapper.terminate(port)
  end
end
