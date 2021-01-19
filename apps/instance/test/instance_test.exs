defmodule Staxx.InstanceTest do
  use ExUnit.Case, async: true

  doctest Staxx.Instance

  import Staxx.Instance.ChainFactory
  alias Staxx.Instance
  alias Staxx.Instance.Stack

  describe "start/1 :: " do
    test "fail to start without existing stack config" do
      assert {:error, "wrong testchain config"} == Instance.start(%{})
      assert {:error, _} = Instance.start(%{"non-existing" => %{"config" => %{}}})
    end

    test "start new testchain if no 'id' passed" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert is_binary(id)
      assert Instance.alive?(id)

      Instance.stop(id)
    end

    test "start existing chain if 'id' passed" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert is_binary(id)
      assert Instance.alive?(id)
      Instance.stop(id)

      {:ok, id} = Instance.start(%{Instance.testchain_key() => %{"config" => %{"id" => id}}})

      assert Instance.alive?(id)
      Instance.stop(id)
    end
  end

  describe "start/3 :: " do
    test "failes with non allowed stacks" do
      {:error, _} = Instance.start(build(:not_allowed_stack))
    end

    test "start new instance with supervisors" do
      {:ok, id} =
        :chain_valid
        |> build()
        |> Map.merge(build(:stack_valid))
        |> Instance.start()

      assert Instance.alive?(id)

      Instance.stop(id)
    end
  end

  describe "stop/1 :: " do
    test "not fail for stop non existing instance" do
      :ok = Instance.stop(Faker.String.base64())
    end

    test "stops running instance and terminates all resources" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert is_binary(id)
      assert Instance.alive?(id)
      Instance.stop(id)
      refute Instance.alive?(id)
    end
  end

  describe "alive?/1 :: " do
    test "validate if instance alive/not" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert is_binary(id)

      assert Instance.alive?(id)
      refute Instance.alive?(Faker.String.base64())

      Instance.stop(id)
    end
  end

  describe "start_stack/2 :: " do
    test "fails if no instance is running" do
      {:error, _} = Instance.start_stack(Faker.String.base64(), "test")
    end

    test "spawns new Stack for running instance" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert is_binary(id)
      assert Instance.alive?(id)

      assert {:ok, pid} = Instance.start_stack(id, "test")
      assert is_pid(pid)
      assert Process.alive?(pid)

      Instance.stop(id)

      refute Process.alive?(pid)
    end
  end

  describe "stop_stack/2 :: " do
    test "stops running Stack" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert is_binary(id)
      assert Instance.alive?(id)

      assert {:ok, pid} = Instance.start_stack(id, "test")
      assert is_pid(pid)
      assert Process.alive?(pid)
      assert Stack.alive?(id, "test")

      assert :ok == Instance.stop_stack(id, "test")

      :timer.sleep(100)
      refute Process.alive?(pid)
      refute Stack.alive?(id, "test")
      # still should be alive
      assert Instance.alive?(id)

      Instance.stop(id)
      refute Instance.alive?(id)
    end
  end

  describe "start_container/3 :: " do
    test "fails without running instance" do
      {:error, _} =
        Instance.start_container(Faker.String.base64(), "test", build(:container_valid))
    end

    test "fails if image is not allowed" do
      {:error, _} =
        Instance.start_container(Faker.String.base64(), "test", build(:container_invalid))
    end

    test "starts new container" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert Instance.alive?(id)
      assert {:ok, _pid} = Instance.start_stack(id, "test")
      assert Stack.alive?(id, "test")

      container = build(:container_valid)
      {:ok, started} = Instance.start_container(id, "test", container)

      assert Map.get(container, :image) == Map.get(started, :image, false)

      Instance.stop(id)
      refute Instance.alive?(id)
      refute Stack.alive?(id, "test")
    end
  end

  describe "info/1 :: " do
    test "empty response without existing instance" do
      nil = Instance.info(Faker.String.base64())
    end

    test "provide info about running instance" do
      {:ok, id} = Instance.start(build(:chain_valid))
      assert Instance.alive?(id)
      assert {:ok, _pid} = Instance.start_stack(id, "test")
      assert Stack.alive?(id, "test")

      container = build(:container_valid)
      {:ok, _} = Instance.start_container(id, "test", container)

      %{"test" => %{containers: containers, stack_name: "test", status: :initializing}} =
        Instance.info(id)

      assert is_list(containers)
      [cont] = containers

      assert Map.get(cont, :image) == Map.get(container, :image, false)
      assert Map.get(cont, :network) == id

      Instance.stop(id)
      refute Instance.alive?(id)
      refute Stack.alive?(id, "test")
    end
  end
end
