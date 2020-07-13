defmodule Staxx.EnvironmentTest do
  use ExUnit.Case, async: true

  doctest Staxx.Environment

  import Staxx.Environment.ChainFactory
  alias Staxx.Environment
  alias Staxx.Environment.Stack

  describe "start/1 :: " do
    test "fail to start without existing stack config" do
      assert {:error, "wrong testchain config"} == Environment.start(%{})
      assert {:error, _} = Environment.start(%{"non-existing" => %{"config" => %{}}})
    end

    test "start new testchain if no 'id' passed" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert is_binary(id)
      assert Environment.alive?(id)

      Environment.stop(id)
    end

    test "start existing chain if 'id' passed" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert is_binary(id)
      assert Environment.alive?(id)
      Environment.stop(id)

      {:ok, id} =
        Environment.start(%{Environment.testchain_key() => %{"config" => %{"id" => id}}})

      assert Environment.alive?(id)
      Environment.stop(id)
    end
  end

  describe "start/3 :: " do
    test "failes with non allowed stacks" do
      {:error, _} = Environment.start(build(:not_allowed_stack))
    end

    test "start new scope with supervisors" do
      {:ok, id} =
        :chain_valid
        |> build()
        |> Map.merge(build(:stack_valid))
        |> Environment.start()

      assert Environment.alive?(id)

      Environment.stop(id)
    end
  end

  describe "stop/1 :: " do
    test "not fail for stop non existing scope" do
      :ok = Environment.stop(Faker.String.base64())
    end

    test "stops running scope and terminates all resources" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert is_binary(id)
      assert Environment.alive?(id)
      Environment.stop(id)
      refute Environment.alive?(id)
    end
  end

  describe "alive?/1 :: " do
    test "validate if scope alive/not" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert is_binary(id)

      assert Environment.alive?(id)
      refute Environment.alive?(Faker.String.base64())

      Environment.stop(id)
    end
  end

  describe "start_stack/2 :: " do
    test "fails if no scope is running" do
      {:error, _} = Environment.start_stack(Faker.String.base64(), "test")
    end

    test "spawns new Stack for running scope" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert is_binary(id)
      assert Environment.alive?(id)

      assert {:ok, pid} = Environment.start_stack(id, "test")
      assert is_pid(pid)
      assert Process.alive?(pid)

      Environment.stop(id)

      refute Process.alive?(pid)
    end
  end

  describe "stop_stack/2 :: " do
    test "stops running Stack" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert is_binary(id)
      assert Environment.alive?(id)

      assert {:ok, pid} = Environment.start_stack(id, "test")
      assert is_pid(pid)
      assert Process.alive?(pid)
      assert Stack.alive?(id, "test")

      assert :ok == Environment.stop_stack(id, "test")

      :timer.sleep(100)
      refute Process.alive?(pid)
      refute Stack.alive?(id, "test")
      # still should be alive
      assert Environment.alive?(id)

      Environment.stop(id)
      refute Environment.alive?(id)
    end
  end

  describe "start_container/3 :: " do
    test "fails without running scope" do
      {:error, _} =
        Environment.start_container(Faker.String.base64(), "test", build(:container_valid))
    end

    test "fails if image is not allowed" do
      {:error, _} =
        Environment.start_container(Faker.String.base64(), "test", build(:container_invalid))
    end

    test "starts new container" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert Environment.alive?(id)
      assert {:ok, pid} = Environment.start_stack(id, "test")
      assert Stack.alive?(id, "test")

      container = build(:container_valid)
      {:ok, started} = Environment.start_container(id, "test", container)

      assert Map.get(container, :image) == Map.get(started, :image, false)

      Environment.stop(id)
      refute Environment.alive?(id)
      refute Stack.alive?(id, "test")
    end
  end

  describe "info/1 :: " do
    test "empty list without running scope" do
      [] = Environment.info(Faker.String.base64())
    end

    test "provide info about running scope" do
      {:ok, id} = Environment.start(build(:chain_valid))
      assert Environment.alive?(id)
      assert {:ok, pid} = Environment.start_stack(id, "test")
      assert Stack.alive?(id, "test")

      container = build(:container_valid)
      {:ok, _} = Environment.start_container(id, "test", container)

      [%{containers: containers, stack_name: "test", status: :initializing}] =
        Environment.info(id)

      assert is_list(containers)
      [cont] = containers

      assert Map.get(cont, :image) == Map.get(container, :image, false)
      assert Map.get(cont, :network) == id

      Environment.stop(id)
      refute Environment.alive?(id)
      refute Stack.alive?(id, "test")
    end
  end
end
