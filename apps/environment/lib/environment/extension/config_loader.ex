defmodule Staxx.Environment.Extension.ConfigLoader do
  @moduledoc """
  Module will load list of extension configs form folder (see: `Application.get_env(:environment, :extensions_dir)`)

  State for config loader will consist of map in format:
  ```elixir
  %{
    "extension_name" => %Staxx.Environment.Extension.Config{},
    "another_extension_name" => %Staxx.Environment.Extension.Config{},
  }
  ```
  """
  use GenServer

  require Logger

  alias Staxx.Environment.Extension.Config
  alias Staxx.Utils

  @extension_config_filename "extension.json"

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    # Check configuration correctness
    if is_nil(config_folder()) do
      raise "#{__MODULE__}: Extensions config folder was not configured !"
    end

    # Validate that extension config folder exist
    unless File.exists?(config_folder()) do
      :ok = Utils.mkdir_p(config_folder())
    end

    state = read()

    Logger.debug(fn ->
      """
      #{__MODULE__}: Loaded list of extension configs
      #{inspect(state, pretty: true)}
      """
    end)

    {:ok, state}
  end

  @doc false
  def handle_call(:get, _from, state),
    do: {:reply, state, state}

  @doc false
  def handle_call({:get, extension_name}, _from, state),
    do: {:reply, Map.get(state, extension_name), state}

  @doc false
  def handle_call({:has_image, extension_name, image}, _from, state) do
    case Map.get(state, extension_name) do
      nil ->
        {:reply, false, state}

      %Config{} = config ->
        {:reply, Config.has_image?(config, image), state}
    end
  end

  @doc false
  def handle_cast(:reload, _state) do
    Logger.debug("#{__MODULE__}: Reloaded list of available extensions")
    {:noreply, read()}
  end

  @doc """
  Get list of available (registered in system) extensions
  """
  @spec get() :: map()
  def get(),
    do: GenServer.call(__MODULE__, :get)

  @doc """
  Get exact extension details
  """
  @spec get(binary) :: map() | nil
  def get(extension_name),
    do: GenServer.call(__MODULE__, {:get, extension_name})

  @doc """
  Check if extension has image in it's config.
  If there is no such docker image in config listed, we couldn't start image
  """
  @spec has_image?(binary, binary) :: boolean
  def has_image?(extension_name, image),
    do: GenServer.call(__MODULE__, {:has_image, extension_name, image})

  @doc """
  Reload all extension configurations from disc.
  """
  @spec reload() :: :ok
  def reload(),
    do: GenServer.cast(__MODULE__, :reload)

  @doc """
  Read list of details from extensions into configured path
  """
  @spec read() :: map()
  def read() do
    config_folder()
    |> File.ls!()
    |> Enum.map(&scan_extension_config/1)
    |> Map.new()
  end

  #
  # Private functions
  #

  defp scan_extension_config(dir) do
    dir
    |> Path.expand(config_folder())
    |> Path.join(@extension_config_filename)
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

  # Get folder with extensions configuration
  defp config_folder(),
    do: Application.get_env(:environment, :extensions_dir)
end
