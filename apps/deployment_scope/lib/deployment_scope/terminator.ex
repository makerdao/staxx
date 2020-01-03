defmodule Staxx.DeploymentScope.Terminator do
  @moduledoc """
  Terminator is here for tracking scope health and in case of testchain failure
  it will kill whole scope. But it wouldn't be back...
  """
  use GenServer

  require Logger

  @doc false
  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc false
  def init(_) do
    Logger.debug(fn -> "Terminator: Come with me if you want to live..." end)
    {:ok, :ok}
  end
end
