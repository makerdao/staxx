defmodule Staxx.Docker.PortMapper do
  @moduledoc """
  Module will store all ports that were mapped for docker containers
  And in case of request it will pick random port number for new container
  """

  use GenServer

  require Logger

  # List of available ports for reservation
  @range 49152..65535

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    Logger.debug("Starting Port Mapper")
    # start ETS
    table = :ets.new(:docker_ports, [:set, :protected])
    {:ok, table}
  end

  @doc false
  def handle_call(:random, from, table) do
    port = Enum.random(@range)

    case :ets.insert_new(table, {port}) do
      true ->
        {:reply, port, table}

      false ->
        handle_call(:random, from, table)
    end
  end

  @doc false
  def handle_call({:reserved?, port}, _from, table) do
    case :ets.lookup(table, port) do
      [] ->
        {:reply, false, table}

      [_] ->
        {:reply, true, table}
    end
  end

  @doc false
  def handle_cast({:terminate, port}, table) do
    :ets.delete(table, port)
    {:noreply, table}
  end

  @doc """
  Get new random port for mapping
  """
  @spec random() :: pos_integer
  def random(), do: GenServer.call(__MODULE__, :random)

  @doc """
  Check if port already reserved by someone
  """
  @spec reserved?(pos_integer) :: boolean
  def reserved?(port) when is_integer(port),
    do: GenServer.call(__MODULE__, {:reserved?, port})

  @doc """
  Remove port from reserved list of ports
  """
  @spec terminate(pos_integer) :: :ok
  def terminate(port) when is_integer(port),
    do: GenServer.cast(__MODULE__, {:terminate, port})

  @doc """
  Removes port from list of reserved ports
  """
  @spec free(pos_integer) :: :ok
  def free(port),
    do: terminate(port)
end
