defmodule Staxx.Docker.ContainerTest do
  use ExUnit.Case

  alias Staxx.Docker.ContainerRegistry
  alias Staxx.Docker.PortMapper
  alias Staxx.Docker.Container

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
             ContainerRegistry
             |> Registry.lookup(name)

    assert :ok = Container.stop(name)

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

    assert PortMapper.reserved?(port)
    assert :ok = Container.stop(name)

    assert_receive {:DOWN, _, :process, ^pid, :normal}

    refute PortMapper.reserved?(port)
  end

  test "info/1 should get all information about container" do
    name = Faker.String.base64()

    container = %Container{
      name: name,
      image: Faker.String.base64(),
      network: Faker.String.base64()
    }

    assert {:ok, pid} =
             container
             |> Container.start_link()

    %Container{name: ^name, image: ^image, network: ^network} = Container.info(name)
    %Container{name: ^name, image: ^image, network: ^network} = Container.info(pid)

    Process.monitor(pid)

    assert :ok = Container.stop(name)

    assert_receive {:DOWN, _, :process, ^pid, :normal}
  end
end
