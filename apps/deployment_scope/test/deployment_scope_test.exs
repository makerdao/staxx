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

      DeploymentScope.stop(id)
    end

    test "start existing chain if 'id' passed"
  end

  describe "start/3 :: " do
    test "failes with non allowed stacks"

    test "start new scope with supervisors"
  end

  describe "stop/1 :: " do
    test "fails for stop non existing scope"

    test "stops running scope and terminates all resources"
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
