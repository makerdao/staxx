defmodule Stacks do
  @moduledoc """
  Set of function for managing stacks
  """

  require Logger

  alias Stacks.WatcherSupervisor
  alias Stacks.Watcher
  alias Stacks.Stack.ConfigLoader
  alias Stacks.Stack.Config

  alias Docker.Struct.Container

  @doc """
  Check if stack is alive ?
  """
  @spec alive?(binary) :: boolean
  def alive?(id),
    do: Watcher.alive?(id)

  @doc """
  List available stacks
  """
  @spec list() :: {:ok, []} | {:error, term}
  def list() do
    {:ok, []}
  end

  @doc """
  Start new stack
  """
  @spec start(map | binary, map, pid | module) :: {:ok, binary} | {:error, term}
  def start(chain_config_or_id, params, notify_pid \\ nil) do
    modules = fetch_stacks(params)
    Logger.debug("Starting new stack with modules: #{inspect(modules)}")

    with :ok <- validate(modules),
         {:ok, id} <- Proxy.start(chain_config_or_id, notify_pid),
         {:ok, _pid} <- WatcherSupervisor.start_watcher(id),
         :ok <- start_stack_list(modules, id) do
      Logger.debug("Started new chain for stack #{id}")
      {:ok, id}
    else
      {:error, err} ->
        Logger.error("Failed to start stack #{inspect(err)}")
        {:error, err}

      err ->
        Logger.error("Failed to start stack #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Starting new container for given stack id
  """
  @spec start_container(binary, binary, Container.t()) :: :ok | {:error, term}
  def start_container(id, stack_name, %Container{image: image} = container) do
    with {:alive, true} <- {:alive, Watcher.alive?(id)},
         {:image, true} <- {:image, ConfigLoader.has_image(stack_name, image)},
         {:ok, %{id: container_id, ports: ports} = container} <- Docker.start(container),
         :ok <- Watcher.add_container(id, stack_name, container_id, ports) do
      {:ok, container}
    else
      {:alive, _} ->
        Logger.error("Stack #{id}: No active stack found for starting new container")
        {:error, "failed to find stack with id #{id}"}

      {:image, _} ->
        Logger.error("Stack #{id}: No image #{image} is allowed for stack #{stack_name}")
        {:error, "#{image} image is not allowed for stack #{stack_name}"}

      err ->
        Logger.error("Stack #{id}: failed to start container #{image} with err: #{inspect(err)}")
        {:error, "failed to start image"}
    end
  end

  @doc """
  Stop running stack
  """
  @spec stop(binary) :: :ok
  def stop(id) do
    Logger.debug("#{id}: Stack stopping")

    with :ok <- Proxy.stop(id),
         :ok <- Watcher.stop(id) do
      :ok
    else
      err ->
        Logger.error("#{id}: Failed to stop stack with error #{inspect(err)}")
    end
  end

  @doc """
  Load information about stack
  """
  @spec info(binary) :: term
  def info(id),
    do: Watcher.info(id)

  @doc """
  Validate if all stacks are allowed to start
  """
  @spec validate([binary]) :: :ok | {:error, term}
  def validate([]), do: :ok

  def validate(list) do
    result =
      list
      |> Enum.reject(&(&1 == "testchain"))
      |> Enum.filter(fn stack_name -> ConfigLoader.get(stack_name) == nil end)

    case result do
      [] ->
        :ok

      list ->
        {:error, "Not all stacks are allowed to be started ! #{inspect(list)}"}
    end
  end

  @doc """
  Sends notification to stack that own container that container has failed
  """
  @spec container_failed(binary) :: :ok | {:error, term}
  def container_failed(container_id) when is_binary(container_id) do
    Stacks.WatcherSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(&send_container_failed(&1, container_id))
  end

  defp start_stack_list([], _id), do: :ok

  defp start_stack_list([stack_name | rest], id) do
    stack_name
    |> ConfigLoader.get()
    |> start_stack(stack_name, id)

    Logger.debug("Stack #{id}: started stack #{stack_name}")
    start_stack_list(rest, id)
  end

  defp start_stack(%Config{manager: image}, stack_name, id) do
    Logger.debug("Stack #{id}: starting manager #{image} for #{stack_name}")
    # Start vdb manager
    container = %Container{
      image: image,
      name: "",
      network: id,
      ports: [],
      env: %{
        "STACK_ID" => id,
        "STACK_NAME" => stack_name,
        "WEB_API_URL" => "http://host.docker.internal:4000",
        "NATS_URL" => "http://host.docker.internal:4222"
      }
    }

    start_container(id, stack_name, container)
  end

  defp start_stack(config, stack_name, id) do
    Logger.error(
      "Stack #{id}: Something wrong with stack #{stack_name} config: #{inspect(config)}"
    )

    {:error, "unknown stack #{stack_name}"}
  end

  # Get list of stacks that need to be started
  defp fetch_stacks(params) when is_map(params) do
    params
    |> Map.keys()
    |> Enum.reject(&(&1 == "testchain"))
  end

  # wrapper function for checking if container relates to stack
  defp send_container_failed({_, pid, _, _}, container_id),
    do: Watcher.container_failed(pid, container_id)
end
