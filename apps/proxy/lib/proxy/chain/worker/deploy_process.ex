defmodule Proxy.Chain.Worker.DeployProcess do
  @moduledoc """
  Deployment process handler.

  While this PID is alive and binded to `Worker` it means deployment process is active.
  It will handle deployment timeouts and other staff related to deployment
  """
  use GenServer

  require Logger

  alias Proxy.Chain.Worker.State

  def start_link(%State{} = _state) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(:ok) do
    {:ok, :ok}
  end
end
