defmodule Stacks.ConfigLoader do
  @moduledoc """
  Module will load list of stack configs form folder.
  """
  use GenServer

  require Logger

  @stack_config_filename "stack.json"

  @stack_docker_compose_file "docker-compose.yml"

  @stack_icon_file "icon.png"

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    state = read()
    Logger.debug("#{__MODULE__}: Loaded list of staks configs")
    {:ok, state}
  end

  @doc false
  def handle_call(:get, _from, state),
    do: {:reply, state, state}

  @doc false
  def handle_call({:get, stack}, _from, state),
    do: {:reply, Map.get(state, stack), state}

  @doc false
  def handle_call({:has_image, stack, image}, _from, state) do
    case Map.get(state, stack) do
      nil ->
        {:reply, false, state}

      %{"docker" => %{"images" => images}} ->
        {:reply, Enum.member?(images, image), state}
    end
  end

  @doc false
  def handle_cast(:reload, _state) do
    updated = read()
    Logger.debug("#{__MODULE__}: Reloaded list of available stacks")
    {:noreply, updated}
  end

  @doc """
  Get list of details
  """
  @spec get() :: map()
  def get(),
    do: GenServer.call(__MODULE__, :get)

  @doc """
  Get exact stack details
  """
  @spec get(binary) :: map() | nil
  def get(stack),
    do: GenServer.call(__MODULE__, {:get, stack})

  @doc """
  Check if stack has image in it's config
  """
  @spec has_image(binary, binary) :: boolean
  def has_image(stack, image),
    do: GenServer.call(__MODULE__, {:has_image, stack, image})

  @doc """
  Reload list of details for all stacks
  """
  @spec reload() :: :ok
  def reload(),
    do: GenServer.cast(__MODULE__, :reload)

  @doc """
  Read list of details from stacks into configured path
  """
  @spec read() :: map()
  def read() do
    config_folder()
    |> File.ls!()
    |> Enum.map(fn name -> {name, scan_stack_config(name)} end)
    |> Map.new()
  end

  defp scan_stack_config(dir) do
    dir
    |> Path.expand(config_folder())
    |> File.ls!()
    |> Enum.map(&Path.expand(&1, Path.join(config_folder(), dir)))
    |> parse_configs()
  end

  defp parse_configs([]), do: nil

  defp parse_configs(list) do
    config =
      list
      |> Enum.find(&String.contains?(&1, @stack_config_filename))
      |> parse_config_file()

    docker =
      list
      |> Enum.find(&String.contains?(&1, @stack_docker_compose_file))
      |> parse_docker_compose_file()

    icon =
      list
      |> Enum.find(&String.contains?(&1, @stack_icon_file))
      |> parse_icon_file()

    %{
      "config" => config,
      "docker" => docker,
      "icon" => icon
    }
  end

  defp parse_config_file(nil), do: nil

  defp parse_config_file(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  defp parse_docker_compose_file(nil), do: nil

  defp parse_docker_compose_file(path) do
    {:ok, %{"services" => details}} =
      path
      |> YamlElixir.read_from_file()

    images =
      details
      |> Map.values()
      |> Enum.map(&Map.get(&1, "image"))
      |> Enum.reject(&(&1 == ""))
      |> Enum.reject(&is_nil/1)

    %{"images" => images, "file" => path}
  end

  defp parse_icon_file(path), do: path

  # Get folder with stacks configuration
  defp config_folder(),
    do: Application.get_env(:stacks, :stacks_dir, "")
end
