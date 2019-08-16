defmodule Staxx.DeploymentScopeTest do
  use ExUnit.Case
  doctest Staxx.DeploymentScope

  import Staxx.DeploymentScope.ChainFactory
  alias Staxx.DeploymentScope

  describe "start/1 :: " do
    test "fail to start without 'testchain' stack" do
      assert {:error, "wrong chain config"} == DeploymentScope.start(%{})
      assert {:error, _} = DeploymentScope.start(%{"vdb" => %{"config" => %{}}})
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
        |> Map.merge(build(:helloworld_valid))
        |> DeploymentScope.start()
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
    test "validate if scope alive/not"
  end

  describe "spawn_stack_manager/2 :: " do
    test "fails if no scope is running"

    test "spawns new StackManger for running scope"
  end

  describe "stop_stack_manager/2 :: " do
    test "stops running StackManager"
  end

  describe "start_container/3 :: " do
    test "fails without running scope"

    test "fails if image is not allowed"

    test "starts new container"
  end

  describe "info/1 :: " do
    test "fails without running scope"

    test "provide info about running scope"
  end
end
