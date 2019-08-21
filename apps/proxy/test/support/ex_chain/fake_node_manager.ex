defmodule Staxx.Proxy.NodeManager.FakeNodeManager do
  @behaviour Staxx.Proxy.NodeManager

  def child_spec(), do: []

  def node(), do: Kernel.node()
end
