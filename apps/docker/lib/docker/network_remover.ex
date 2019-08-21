defmodule Staxx.Docker.NetworkRemover do
  @moduledoc """
  Module removes unused networks for docker env

  It's very simple reccuring executer for command.
  Some sort of a cron job. But way more simple, lightweight and OTP based
  """
  use GenServer

  alias Staxx.Docker

  require Logger

  @timeout 360_000
  # @timeout 10_000

  @doc false
  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc false
  def init(:ok),
    do: {:ok, :ok, @timeout}

  @doc false
  def handle_info(:timeout, state) do
    Logger.debug(fn -> "Clearing unused docker netwrorks" end)
    Docker.prune_networks()
    {:noreply, state, @timeout}
  end
end
