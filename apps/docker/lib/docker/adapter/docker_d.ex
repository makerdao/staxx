defmodule Staxx.Docker.Adapter.DockerD do
  @moduledoc """
  Set of docker commands that will be running on read docker daemon
  """
  @behaviour Staxx.Docker

  require Logger

  alias Staxx.Docker.Container

  @doc """
  Start given container 

  Will conbine `docker run` command based on given Container structure.
  ```sh
  docker run --name=postgres-vdb -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
  ```
  """
  @impl true
  @spec run(Container.t()) :: {:ok, Container.t()} | {:error, term}
  def run(%Container{network: network} = container) do
    Logger.debug(fn ->
      """
      Try to run new container:
        #{inspect(container, pretty: true)}
      """
    end)

    if network != "" do
      create_network(network)
    end

    id_or_err =
      container
      |> build_run_params()
      |> exec()

    case String.match?(id_or_err, ~r/[a-z0-9]{64}/) do
      true ->
        container = %Container{container | id: id_or_err}

        Logger.debug(fn ->
          """
          New Docker container spawned with details:
            #{inspect(container, pretty: true)}
          """
        end)

        {:ok, container}

      false ->
        Logger.error("Failed to run container with code: #{id_or_err}")
        {:error, id_or_err}
    end
  end

  @doc """
  Starts existing container in system
  """
  @impl true
  @spec start(binary) :: :ok | {:error, term}
  def start(id_or_name) do
    [
      executable!(),
      "start",
      id_or_name
    ]
    |> exec()
    |> case do
      ^id_or_name ->
        :ok

      data ->
        {:error, data}
    end
  end

  @doc """
  Get logs for docker container
  """
  @impl true
  @spec logs(binary) :: binary
  def logs(id_or_name) do
    [
      executable!(),
      "logs",
      id_or_name
    ]
    |> exec()
  end

  @doc """
  Remove docker container
  """
  @impl true
  @spec rm(binary) :: :ok | {:error, term}
  def rm(id_or_name) do
    [
      executable!(),
      "rm",
      "-f",
      id_or_name
    ]
    |> exec()
    |> case do
      ^id_or_name ->
        :ok

      data ->
        {:error, data}
    end
  end

  @doc """
  Stop running container
  """
  @impl true
  @spec stop(binary) :: :ok | {:error, term}
  def stop(""), do: {:error, "No container id passed"}

  def stop(id_or_name) do
    Logger.debug("Stopping container #{id_or_name}")

    case System.cmd(executable!(), ["stop", id_or_name]) do
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
  @impl true
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
  @impl true
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
  @impl true
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
  Get nats docker network name for staxx
  """
  @impl true
  @spec get_nats_network() :: binary
  def get_nats_network() do
    # Logger.debug("Get nats docker network name for staxx")

    # case System.cmd(executable!(), [
    #        "inspect",
    #        "nats.local",
    #        "--format={{.HostConfig.NetworkMode}}"
    #      ]) do
    #   {name, 0} ->
    #     name
    #     |> String.trim()

    #   {err, exit_status} ->
    #     Logger.error("Failed to get nats network name: #{exit_status} - #{inspect(err)}")
    #     ""
    # end
    "container:nats.local"
  end

  @doc """
  Join container to network
  """
  @impl true
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

  defp build_run_params(%Container{image: image, cmd: cmd} = container, mode \\ ["-d"]) do
    [
      executable!(),
      "run",
      mode,
      build_rm(container),
      build_network(container),
      build_name(container),
      build_ports(container),
      build_env(container),
      build_volumes(container),
      image,
      cmd
    ]
  end

  # If container is in `dev_mode` we don't need to run it with `--rm` falgs.
  # So ssytem will ignore `rm` flag from `Container.t()`
  # We might need some logs from container
  defp build_rm(%Container{rm: rm} = container) do
    case Container.is_dev_mode(container) do
      true ->
        ""

      _ ->
        case rm do
          true ->
            "--rm"

          _ ->
            ""
        end
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

  defp build_volumes(%Container{volumes: []}), do: ""

  defp build_volumes(%Container{volumes: volumes}) do
    volumes
    |> Enum.map(fn volume -> ["-v", volume] end)
    |> List.flatten()
  end

  defp build_env(%Container{env: []}), do: []

  defp build_env(%Container{env: env}) do
    env
    |> Enum.map(fn {key, val} -> ["-e", "'#{key}=#{val}'"] end)
    |> List.flatten()
  end

  defp exec(command) when is_list(command) do
    command
    |> List.flatten()
    |> Enum.reject(&(bit_size(&1) == 0))
    |> Enum.join(" ")
    |> exec()
  end

  defp exec(command) when is_binary(command) do
    command
    |> String.to_charlist()
    |> :os.cmd()
    |> to_string()
    |> String.trim()
  end
end
