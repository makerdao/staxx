defmodule Stacks do
  @moduledoc """
  Set of function for managing stacks
  """

  require Logger

  alias Stacks.WatcherSupervisor
  alias Stacks.Watcher

  alias Docker.Struct.Container

  @doc """
  Start new stack
  """
  @spec start(map, map, pid | module) :: {:ok, binary} | {:error, term}
  def start(chain_config, params, notify_pid \\ nil) do
    modules = fetch_stacks(params)
    # TODO: validate stacks
    Logger.debug("Starting new stack with modules: #{inspect(modules)}")

    with {:ok, id} <- Proxy.start(chain_config, notify_pid),
         {:ok, _pid} <- WatcherSupervisor.start_watcher(id),
         :ok <- start_stack_list(modules, id) do
      Logger.debug("Started new chain for stack #{id}")
      {:ok, id}
    else
      {:error, err} ->
        Logger.error("Failed to start stack #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Starting new container for given stack id
  """
  @spec start_container(binary, Container.t()) :: :ok | {:error, term}
  def start_container(id, %Container{} = container) do
    with true <- Watcher.alive?(id),
         {:ok, %{id: container_id} = container} <- Proxy.Chain.Docker.start(container),
         :ok <- Watcher.add_container(id, container_id) do
      {:ok, container}
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

  defp start_stack_list([], _id), do: :ok
  defp start_stack_list([name | rest], id) do
    start_stack(name, id)
    start_stack_list(rest, id)
  end

  defp start_stack("vdb", id) do
    # Start vdb manager
    container = %Container{
      image: "testchain-vdb",
      name: "",
      network: id,
      ports: [],
      env: %{
        "STACK_ID" => id,
        "WEB_API_URL" => "http://host.docker.internal:4000",
        "NATS_URL" => "http://host.docker.internal:4222"
      }
    }
    start_container(id, container)
  end
  defp start_stack(name, _id), do: {:error, "unknown stack #{name}"}

  # Get list of stacks that need to be started
  defp fetch_stacks(params) when is_map(params) do
    params
    |> Map.keys()
    |> Enum.reject(&(&1 == "testchain"))
  end
end
