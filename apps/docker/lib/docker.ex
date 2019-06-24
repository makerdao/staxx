defmodule Docker do
  @moduledoc """
  Set of docker commands
  """
  require Logger

  alias Docker.Struct.Container

  @doc """
  Start new docker container using given details
  """
  @callback start_rm(container :: Container.t()) ::
              {:ok, Container.t()} | {:error, term}

  @doc """
  Stop running container
  """
  @callback stop(id :: binary) :: :ok | {:error, term}

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
  Join container to network
  """
  @callback join_network(id :: binary, container_id :: binary) :: {:ok, term} | {:error, term}

  # docker run --name=postgres-vdb -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
  @spec start_rm(Container.t()) ::
          {:ok, Container.t()} | {:error, term}
  def start_rm(%Container{id: id}) when bit_size(id) > 0,
    do: {:error, "Could not start container with id"}

  def start_rm(%Container{image: ""}),
    do: {:error, "Could not start container without image"}

  def start_rm(%Container{network: ""}),
    do: {:error, "Could not start container without network"}

  def start_rm(%Container{name: ""} = container),
    do: start_rm(%Container{container | name: random_name()})

  def start_rm(%Container{} = container) do
    container = Container.reserve_ports(container)

    case adapter().start_rm(container) do
      {:ok, updated} ->
        {:ok, updated}

      {:error, msg} ->
        # Have to free ports if start failed
        container
        |> Container.free_ports()

        {:error, msg}
    end
  end

  @doc """
  Stop running container
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(""),
    do: {:error, "No container id passed"}

  def stop(container_id),
    do: adapter().stop(container_id)

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
end
