defmodule Docker.Struct.ContainerTest do
  use ExUnit.Case

  alias Docker.Struct.Container

  test "fail to start without id" do
    assert {:error, _} = Container.start_link(%Container{id: ""})
  end

  test "should start new container and reserve id" do
    id = Faker.String.base64()

    assert {:ok, pid} =
             %Container{id: id}
             |> Container.start_link()

    Process.monitor(pid)

    assert {:error, {:already_started, ^pid}} =
             %Container{id: id}
             |> Container.start_link()

    assert [{^pid, nil}] =
             Docker.ContainerRegistry
             |> Registry.lookup(id)

    assert :ok = Container.terminate(id)

    assert_receive {:DOWN, _, :process, ^pid, :normal}
  end

  test "should reserve port and release on stop" do
    id = Faker.String.base64()

    %{ports: [{port, 3000}]} =
      container =
      %Container{
        id: id,
        ports: [3000]
      }
      |> Container.reserve_ports()

    assert {:ok, pid} = Container.start_link(container)

    Process.monitor(pid)

    assert Docker.PortMapper.reserved?(port)
    assert :ok = Container.terminate(id)

    assert_receive {:DOWN, _, :process, ^pid, :normal}

    refute Docker.PortMapper.reserved?(port)
  end
end
