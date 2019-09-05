defmodule Staxx.Proxy.NodeManager.Local do
  @moduledoc """
  Local Node manager.
  It does nothing except of always saying that ex_chain is on same node as staxx
  """
  require Logger

  alias Staxx.Proxy.NodeManager

  @behaviour NodeManager

  @impl NodeManager
  def child_spec(), do: []

  @impl NodeManager
  def node(), do: Kernel.node()

end
