defmodule Docker.Struct.ContainerTest do
  use ExUnit.Case

  alias Docker.Struct.Container

  test "should start new container and reserve id" do
    name = Faker.String.base64()

    container = %Container{
      name: name,
      image: Faker.String.base64(),
      network: Faker.String.base64()
    }

    assert {:ok, pid} =
             container
             |> Container.start_link()

    Process.monitor(pid)

    assert {:error, {:already_started, ^pid}} =
             container
             |> Container.start_link()

    assert [{^pid, nil}] =
             Docker.ContainerRegistry
             |> Registry.lookup(name)

    assert :ok = Container.terminate(name)

    assert_receive {:DOWN, _, :process, ^pid, :normal}
  end

  test "should reserve port and release on stop" do
    name = Faker.String.base64()

    %{ports: [{port, 3000}]} =
      container =
      %Container{
        name: name,
        ports: [3000],
        image: Faker.String.base64(),
        network: Faker.String.base64()
      }
      |> Container.reserve_ports()

    assert {:ok, pid} = Container.start_link(container)

    Process.monitor(pid)

    assert Docker.PortMapper.reserved?(port)
    assert :ok = Container.terminate(name)

    assert_receive {:DOWN, _, :process, ^pid, :normal}

    refute Docker.PortMapper.reserved?(port)
  end
end
