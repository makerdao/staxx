defmodule Docker.Cmd do
  @moduledoc """
  List of commands that docker could execute
  Idea is about cross node communication.
  All other nodes will use this genserver to call something
  """

  use GenServer
  require Logger

  alias Docker.Struct.Container

  # Timeout for calling actions
  @timeout 30_000

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(_) do
    unless Docker.executable!() do
      raise "No docker executable found in system"
    end

    {:ok, nil}
  end

  @doc false
  def handle_call({:start, %Container{} = container}, _from, state) do
    res =
      Docker
      |> Task.async(:start_rm, [container])
      |> Task.await(@timeout)

    {:reply, res, state}
  end

  @doc false
  def handle_call({:stop, id}, _from, state) do
    res =
      Docker
      |> Task.async(:stop, [id])
      |> Task.await(@timeout)

    {:reply, res, state}
  end

  @doc false
  def handle_call({:join_network, id, container}, _from, state) do
    res =
      Docker
      |> Task.async(:join_network, [id, container])
      |> Task.await(@timeout)

    {:reply, res, state}
  end

  @doc false
  def handle_cast(:prune_networks, state) do
    Docker
    |> Task.async(:prune_networks, [])
    |> Task.await(@timeout)

    {:noreply, state}
  end

  @doc """
  Start new container
  """
  @spec start(Docker.Struct.Container.t()) :: {:ok, Docker.Struct.Container.t()} | {:error, term}
  def start(%Container{} = container),
    do: GenServer.call(__MODULE__, {:start, container}, @timeout)

  @doc """
  Stop runing continer
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(id),
    do: GenServer.call(__MODULE__, {:stop, id}, @timeout)
end
