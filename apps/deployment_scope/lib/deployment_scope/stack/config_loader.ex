defmodule Staxx.DeploymentScope.Stack.ConfigLoader do
  @moduledoc """
  Module will load list of stack configs form folder (see: `Application.get_env(:deployment_scope, :stacks_dir)`)

  State for config loader will consist of map in format:
  ```elixir
  %{
    "stack_name" => %Staxx.DeploymentScope.Stack.Config{},
    "another_stack_name" => %Staxx.DeploymentScope.Stack.Config{},
  }
  ```
  """
  use GenServer

  require Logger

  alias Staxx.DeploymentScope.Stack.Config
  alias Staxx.Utils

  @stack_config_filename "stack.json"

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    # Check configuration correctness
    if is_nil(config_folder()) do
      raise "Stack config folder was not configured !"
    end

    # Validate that stack config folder exist
    unless File.exists?(config_folder()) do
      Utils.mkdir_p(config_folder())
    end

    state = read()

    Logger.debug(fn ->
      """
      #{__MODULE__}: Loaded list of staks configs
      #{inspect(state, pretty: true)}
      """
    end)

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

      %Config{} = config ->
        {:reply, Config.has_image?(config, image), state}
    end
  end

  @doc false
  def handle_cast(:reload, _state) do
    updated = read()
    Logger.debug("#{__MODULE__}: Reloaded list of available stacks")
    {:noreply, updated}
  end

  @doc """
  Get list of available (registered in system) stacks
  """
  @spec get() :: map()
  def get(),
    do: GenServer.call(__MODULE__, :get)

  @doc """
  Get exact stack details
  """
  @spec get(binary) :: map() | nil
  def get(stack_name),
    do: GenServer.call(__MODULE__, {:get, stack_name})

  @doc """
  Check if stack has image in it's config.
  If there is no such docker image in config listed, we couldn't start image
  """
  @spec has_image?(binary, binary) :: boolean
  def has_image?(stack_name, image),
    do: GenServer.call(__MODULE__, {:has_image, stack_name, image})

  @doc """
  Reload stack configuration from disc.
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
    |> Enum.map(&scan_stack_config/1)
    |> Map.new()
  end

  #
  # Private functions
  #

  defp scan_stack_config(dir) do
    dir
    |> Path.expand(config_folder())
    |> Path.join(@stack_config_filename)
    |> parse_config_file()
  end

  defp parse_config_file(nil), do: nil
  defp parse_config_file(""), do: nil

  defp parse_config_file(path) do
    config =
      path
      |> File.read!()
      |> Poison.decode!(as: %Config{}, keys: :atoms)

    {Map.get(config, :name), config}
  end

  # Get folder with stacks configuration
  defp config_folder(),
    do: Application.get_env(:deployment_scope, :stacks_dir)
end
