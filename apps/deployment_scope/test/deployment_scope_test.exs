defmodule DeploymentScopeTest do
  use ExUnit.Case
  doctest DeploymentScope

  test "greets the world" do
    assert DeploymentScope.hello() == :world
  end
end
