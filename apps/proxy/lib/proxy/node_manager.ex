defmodule Staxx.Proxy.NodeManager do
  @moduledoc """
  Node manager behaviour
  """

  @doc """
  Child spec for node manager
  """
  @callback child_spec() :: Supervisor.child_spec()

  @doc """
  Get chain node address
  """
  @callback node() :: node()

  @doc """
  Get child specs from adapter
  """
  @spec child_spec() :: Supervisor.child_spec()
  def child_spec(),
    do: adapter().child_spec()

  @doc """
  Get chain node address from adapter
  """
  @spec node() :: node()
  def node(),
    do: adapter().node()

  defp adapter(),
    do: Application.get_env(:proxy, :node_manager_adapter)
end
