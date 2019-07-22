defmodule Docker.Adapter.DockerD do
  @moduledoc """
  Set of docker commands that will be running on read docker daemon
  """
  @behaviour Docker

  require Logger

  alias Docker.Struct.Container

  # docker run --name=postgres-vdb -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
  def start(%Container{network: network} = container) do
    Logger.debug("Try to start new container #{inspect(container)}")

    if network != "" do
      create_network(network)
    end

    case System.cmd(executable!(), build_start_params(container)) do
      {id, 0} ->
        id = String.replace(id, "\n", "")
        container = %Container{container | id: id}

        Logger.debug(fn ->
          """
          New Docker container spawned with details:
            #{inspect(container, pretty: true)}
          """
        end)

        {:ok, container}

      {err, exit_status} ->
        Logger.error("Failed to start container with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Stop running container
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(""), do: {:error, "No container id passed"}

  def stop(container_id) do
    Logger.debug("Stopping container #{container_id}")

    case System.cmd(executable!(), ["stop", container_id]) do
      {id, 0} ->
        {:ok, String.replace(id, "\n", "")}

      {err, exit_status} ->
        Logger.error("Failed to stop container with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Create new docker network for stack
  """
  @spec create_network(binary) :: {:ok, binary} | {:error, term}
  def create_network(id) do
    Logger.debug("Creating new docker network #{id}")

    case System.cmd(executable!(), ["network", "create", id]) do
      {res, 0} ->
        {:ok, String.replace(res, "\n", "")}

      {err, exit_status} ->
        Logger.error("Failed to create network with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Remove docker network
  """
  @spec rm_network(binary) :: :ok | {:error, term}
  def rm_network(id) do
    Logger.debug("Removing new docker network #{id}")

    case System.cmd(executable!(), ["network", "rm", id]) do
      {_res, 0} ->
        :ok

      {err, exit_status} ->
        Logger.error("Failed to remove network #{id} with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Remove all unused docker networks
  """
  @spec prune_networks() :: :ok | {:error, term}
  def prune_networks() do
    Logger.debug("Removing all docker unused networks")

    case System.cmd(executable!(), ["network", "prune", "-f"]) do
      {_res, 0} ->
        :ok

      {err, exit_status} ->
        Logger.error("Failed to remove networks with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Join container to network
  """
  @spec join_network(binary, binary) :: {:ok, term} | {:error, term}
  def join_network(id, container_id) do
    Logger.debug("Adding new docker container #{container_id} to network #{id}")

    case System.cmd(executable!(), ["network", "connect", id, container_id]) do
      {res, 0} ->
        {:ok, String.replace(res, "\n", "")}

      {err, exit_status} ->
        Logger.error("Failed to create network with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  #
  # Private functions
  #

  # Get docker executable
  defp executable!(), do: System.find_executable("docker")

  defp build_start_params(%Container{image: image, cmd: cmd} = container) do
    [
      "run",
      "-d",
      build_rm(container),
      build_network(container),
      build_name(container),
      build_ports(container),
      build_env(container),
      image,
      cmd
    ]
    |> List.flatten()
    |> Enum.reject(&(bit_size(&1) == 0))
  end

  # If container is in `dev_mode` we don't need to run it with `--rm` falgs.
  # We might need some logs from container
  defp build_rm(container) do
    case Container.is_dev_mode(container) do
      true ->
        ""

      _ ->
        "--rm"
    end
  end

  defp build_name(%Container{name: ""}), do: ""

  # defp build_name(%Container{name: name}), do: ["--name", name, "-h", name, "--network-alias", name]
  defp build_name(%Container{name: name}), do: ["--name", name]
  defp build_name(_container), do: ""

  defp build_network(%Container{network: ""}), do: ""
  defp build_network(%Container{network: network}), do: ["--network", network]
  defp build_network(_container), do: ""

  defp build_ports(%Container{ports: []}), do: ""

  defp build_ports(%Container{ports: ports}) do
    ports
    |> Enum.map(&build_port/1)
    |> List.flatten()
  end

  defp build_port({port, to_port}), do: ["-p", "#{port}:#{to_port}"]
  defp build_port(port) when is_integer(port), do: ["-p", "#{port}:#{port}"]
  defp build_port(_), do: ""

  defp build_env(%Container{env: []}), do: []

  defp build_env(%Container{env: env}) do
    env
    |> Enum.map(fn {key, val} -> ["--env", "#{key}=#{val}"] end)
    |> List.flatten()
  end
end
