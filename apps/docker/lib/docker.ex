defmodule Staxx.Docker do
  @moduledoc """
  Set of docker commands
  """
  require Logger

  alias Staxx.Docker.Container
  alias Staxx.Docker.Struct.SyncResult

  # Sync docker operation timeout
  @timeout Application.get_env(:docker, :sync_timmeout, 180_000)

  @doc """
  Start existing container in system
  """
  @callback start(id_or_name :: binary) :: :ok | {:error, term}

  @doc """
  Start new docker container using given details
  """
  @callback run(container :: Container.t()) ::
              {:ok, Container.t()} | {:error, term}

  @doc """
  Stop running container
  """
  @callback stop(id_or_name :: binary) :: :ok | {:error, term}

  @doc """
  Load logs from container with given ID
  """
  @callback logs(id_or_name :: binary) :: binary

  @doc """
  Remove container with given ID or name
  """
  @callback rm(id_or_name :: binary) :: :ok | {:error, term}

  @doc """
  Create new docker network with given ID for stack
  """
  @callback create_network(id :: binary) :: {:ok, binary} | {:error, term}

  @doc """
  Remove docker network with id
  """
  @callback rm_network(id :: binary) :: :ok | {:error, term}

  @doc """
  Remove all unused docker networks
  """
  @callback prune_networks() :: :ok | {:error, term}

  @doc """
  Get nats docker network name for staxx
  """
  @callback get_nats_network() :: binary

  @doc """
  Join container to network
  """
  @callback join_network(id :: binary, container_id :: binary) :: {:ok, term} | {:error, term}

  @doc """
  Check if dev mode is allowed for starting docker containers
  """
  @spec dev_mode_allowed?() :: boolean
  def dev_mode_allowed?(),
    do: Application.get_env(:docker, :dev_mode_allowed) == "true"

  @doc """
  Starts existing container in system
  """
  @spec start(binary) :: :ok | {:error, term}
  def start(id_or_name),
    do: adapter().start(id_or_name)

  # docker run --name=postgres-vdb -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
  @spec run(Container.t()) ::
          {:ok, Container.t()} | {:error, term}
  def run(%Container{id: id}) when bit_size(id) > 0,
    do: {:error, "Could not start container with id"}

  def run(%Container{image: ""}),
    do: {:error, "Could not start container without image"}

  # def run(%Container{network: ""}),
  #   do: {:error, "Could not start container without network"}

  def run(%Container{name: ""} = container),
    do: run(%Container{container | name: random_name()})

  def run(%Container{} = container) do
    container = Container.reserve_ports(container)

    case adapter().run(container) do
      {:ok, updated} ->
        {:ok, updated}

      {:error, msg} ->
        # Have to free ports if starting process failed
        container
        |> Container.free_ports()

        {:error, msg}
    end
  end

  @doc """
  Run container in sync mode. 
  Means that system will run container and will wait for it's termination.
  As a result function will return all output from running container.

  Note: 
    `rm` flag will be controlled by system.
    `permanent` option will also be set to `false`
    `ports` will be replaced with `[]`
  """
  @spec run_sync(Container.t()) :: SyncResult.t()
  def run_sync(%Container{name: ""} = container),
    do: run_sync(%Container{container | name: random_name()})

  def run_sync(%Container{name: name} = container) do
    Task.async(fn ->
      # Set trap exit for next Container pid
      Process.flag(:trap_exit, true)

      %Container{container | permanent: false, rm: false, ports: []}
      |> Container.start_link()
      |> receive_exit()
      |> case do
        {:ok, exit_code} ->
          data = logs(name)
          # Remove docker image
          rm(name)
          %SyncResult{status: exit_code, data: data}

        {:error, err} ->
          %SyncResult{err: err, status: 1}
      end
    end)
    |> Task.await(@timeout)
  end

  @doc """
  Stop running container
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(""),
    do: {:error, "No container id passed"}

  def stop(id_or_name),
    do: adapter().stop(id_or_name)

  @doc """
  Load list of logs from docker container
  """
  @spec logs(binary) :: binary
  def logs(""),
    do: ""

  def logs(id_or_name),
    do: adapter().logs(id_or_name)

  @doc """
  Remove Docker container
  """
  @spec rm(binary) :: :ok | {:error, term}
  def rm(""), do: :ok

  def rm(id_or_name),
    do: adapter().rm(id_or_name)

  @doc """
  Create new docker network for stack
  """
  @spec create_network(binary) :: {:ok, binary} | {:error, term}
  def create_network(id),
    do: adapter().create_network(id)

  @doc """
  Remove docker network
  """
  @spec rm_network(binary) :: :ok | {:error, term}
  def rm_network(id),
    do: adapter().rm_network(id)

  @doc """
  Remove all unused docker networks
  """
  @spec prune_networks() :: :ok | {:error, term}
  def prune_networks(),
    do: adapter().prune_networks()

  @doc """
  Get nats docker network name for staxx
  """
  @spec get_nats_network() :: binary
  def get_nats_network(),
    do: adapter().get_nats_network()

  @doc """
  Join container to network
  """
  @spec join_network(binary, binary) :: {:ok, term} | {:error, term}
  def join_network(id, container),
    do: adapter().join_network(id, container)

  @doc """
  Generate random name for container
  """
  @spec random_name(pos_integer) :: binary
  def random_name(length \\ 48) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
    |> String.replace("-", "")
    |> String.replace("_", "")
    |> String.replace(".", "")
    |> String.downcase()
  end

  @doc """
  Get configured Docker adapter for application
  """
  def adapter() do
    Application.get_env(:docker, :adapter) ||
      raise ArgumentError, "`:adapter` required to be configured"
  end

  # Handle docker tap message
  defp receive_exit({:ok, pid}) do
    receive do
      {:EXIT, ^pid, {:shutdown, exit_code}} ->
        {:ok, exit_code}

      _ ->
        receive_exit({:ok, pid})
    after
      @timeout ->
        {:erorr, :timeout}
    end
  end

  defp receive_exit(_), do: {:error, "unknown process for traping exit"}
end
