defmodule Staxx.DeploymentScopeTest do
  use ExUnit.Case, async: true

  doctest Staxx.DeploymentScope

  import Staxx.DeploymentScope.ChainFactory
  alias Staxx.DeploymentScope
  alias Staxx.DeploymentScope.Scope.StackManager

  describe "start/1 :: " do
    test "fail to start without existing stack config" do
      assert {:error, "wrong chain config"} == DeploymentScope.start(%{})
      assert {:error, _} = DeploymentScope.start(%{"non-existing" => %{"config" => %{}}})
    end

    test "start new testchain if no 'id' passed" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert is_binary(id)
      assert DeploymentScope.alive?(id)

      DeploymentScope.stop(id)
    end

    test "start existing chain if 'id' passed" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert is_binary(id)
      assert DeploymentScope.alive?(id)
      DeploymentScope.stop(id)

      {:ok, id} = DeploymentScope.start(%{"testchain" => %{"config" => %{"id" => id}}})
      assert DeploymentScope.alive?(id)
      DeploymentScope.stop(id)
    end
  end

  describe "start/3 :: " do
    test "failes with non allowed stacks" do
      {:error, _} = DeploymentScope.start(build(:not_allowed_stack))
    end

    test "start new scope with supervisors" do
      {:ok, id} =
        :chain_valid
        |> build()
        |> Map.merge(build(:stack_valid))
        |> DeploymentScope.start()

      assert DeploymentScope.alive?(id)

      DeploymentScope.stop(id)
    end
  end

  describe "stop/1 :: " do
    test "not fail for stop non existing scope" do
      :ok = DeploymentScope.stop(Faker.String.base64())
    end

    test "stops running scope and terminates all resources" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert is_binary(id)
      assert DeploymentScope.alive?(id)
      DeploymentScope.stop(id)
      refute DeploymentScope.alive?(id)
    end
  end

  describe "alive?/1 :: " do
    test "validate if scope alive/not" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert is_binary(id)

      assert DeploymentScope.alive?(id)
      refute DeploymentScope.alive?(Faker.String.base64())

      DeploymentScope.stop(id)
    end
  end

  describe "spawn_stack_manager/2 :: " do
    test "fails if no scope is running" do
      {:error, _} = DeploymentScope.spawn_stack_manager(Faker.String.base64(), "test")
    end

    test "spawns new StackManger for running scope" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert is_binary(id)
      assert DeploymentScope.alive?(id)

      assert {:ok, pid} = DeploymentScope.spawn_stack_manager(id, "test")
      assert is_pid(pid)
      assert Process.alive?(pid)

      DeploymentScope.stop(id)

      refute Process.alive?(pid)
    end
  end

  describe "stop_stack_manager/2 :: " do
    test "stops running StackManager" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert is_binary(id)
      assert DeploymentScope.alive?(id)

      assert {:ok, pid} = DeploymentScope.spawn_stack_manager(id, "test")
      assert is_pid(pid)
      assert Process.alive?(pid)
      assert StackManager.alive?(id, "test")

      assert :ok == DeploymentScope.stop_stack_manager(id, "test")

      :timer.sleep(100)
      refute Process.alive?(pid)
      refute StackManager.alive?(id, "test")
      # still shoul dbe alive
      assert DeploymentScope.alive?(id)

      DeploymentScope.stop(id)
      refute DeploymentScope.alive?(id)
    end
  end

  describe "start_container/3 :: " do
    test "fails without running scope" do
      {:error, _} =
        DeploymentScope.start_container(Faker.String.base64(), "test", build(:container_valid))
    end

    test "fails if image is not allowed" do
      {:error, _} =
        DeploymentScope.start_container(Faker.String.base64(), "test", build(:container_invalid))
    end

    test "starts new container" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert DeploymentScope.alive?(id)
      assert {:ok, pid} = DeploymentScope.spawn_stack_manager(id, "test")
      assert StackManager.alive?(id, "test")

      container = build(:container_valid)
      {:ok, started} = DeploymentScope.start_container(id, "test", container)

      assert Map.get(container, :image) == Map.get(started, :image, false)

      DeploymentScope.stop(id)
      refute DeploymentScope.alive?(id)
      refute StackManager.alive?(id, "test")
    end
  end

  describe "info/1 :: " do
    test "empty list without running scope" do
      [] = DeploymentScope.info(Faker.String.base64())
    end

    test "provide info about running scope" do
      {:ok, id} = DeploymentScope.start(build(:chain_valid))
      assert DeploymentScope.alive?(id)
      assert {:ok, pid} = DeploymentScope.spawn_stack_manager(id, "test")
      assert StackManager.alive?(id, "test")

      container = build(:container_valid)
      {:ok, _} = DeploymentScope.start_container(id, "test", container)

      [%{containers: containers, stack_name: "test", status: :initializing}] =
        DeploymentScope.info(id)

      assert is_list(containers)
      [cont] = containers

      assert Map.get(cont, :image) == Map.get(container, :image, false)
      assert Map.get(cont, :network) == id

      DeploymentScope.stop(id)
      refute DeploymentScope.alive?(id)
      refute StackManager.alive?(id, "test")
    end
  end
end
