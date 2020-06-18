defmodule Staxx.Environment do
  @moduledoc """
  Module is responsible for aggregation of testchain + extensions functions in one place.
  It handles and manages starting testchain/extensions in correct order and does input validation.
  """

  require Logger

  alias Staxx.Docker
  alias Staxx.Docker.Container
  alias Staxx.Testchain
  alias Staxx.Testchain.Helper
  alias Staxx.Environment.DynamicSupervisor, as: EnvironmentsDynamicSupervisor
  alias Staxx.Environment.Environment.Supervisor, as: EnvironmentSupervisor
  alias Staxx.Environment.Extension
  alias Staxx.Environment.Extension.ConfigLoader

  # Hardcoded testchain "extension" key. 
  @testchain_key "testchain"

  @doc """
  Get predefined Testchain "extension" config anme.
  """
  @spec testchain_key() :: binary
  def testchain_key(), do: @testchain_key

  @doc """
  Starts new environment using given configuration.
  """
  @spec start(map, binary) :: {:ok, binary} | {:error, term}
  def start(params, email \\ "")

  def start(%{@testchain_key => %{"config" => %{"id" => id}}} = params, email) do
    extensions = Map.drop(params, [@testchain_key])

    Logger.debug(fn ->
      """
      Starting environment with existing testchain #{id}
      Config:
      #{inspect(extensions, pretty: true)}
      """
    end)

    start(id, id, extensions, email)
  end

  def start(%{@testchain_key => %{"config" => config}} = params, email) do
    chain_config =
      config
      |> Helper.config_from_payload()
      |> Helper.generate_id!()

    extensions = Map.drop(params, [@testchain_key])

    Logger.debug(fn ->
      """
      Starting environment with new testchain
      Testchain configuration:
      #{inspect(chain_config, pretty: true)}

      Extensions Config:
      #{inspect(extensions, pretty: true)}
      """
    end)

    start(chain_config.id, chain_config, extensions, email)
  end

  def start(_, _),
    do: {:error, "wrong testchain config"}

  @doc """
  Start supervision tree for new environment
  """
  @spec start(binary, binary | map, map, binary) :: {:ok, Testchain.evm_id()} | {:error, term}
  def start(id, chain_config_or_id, extensions, email \\ "") when is_binary(id) do
    extension_names = get_extension_names(extensions)
    Logger.debug("Starting new environment with extensions: #{inspect(extension_names)}")

    # Binding email to chain configuration
    chain_config_or_id =
      chain_config_or_id
      |> case do
        config when is_map(config) ->
          Map.put(config, :email, email)

        id ->
          id
      end

    with :ok <- validate_extensions(extension_names),
         {:ok, pid} <-
           EnvironmentsDynamicSupervisor.start_environment({id, chain_config_or_id, extensions}) do
      Logger.debug("Environment #{id}: Started supervisor tree #{inspect(pid)}")

      {:ok, id}
    else
      {:error, err} ->
        Logger.error("Failed to start environment: #{inspect(err)}")
        {:error, err}

      err ->
        Logger.error("Failed to start environment: #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Spawns new extension manager service.
  Helpful for dynamically starting new extensions for existing environment that already running.
  """
  @spec start_extension(binary, binary) :: DynamicSupervisor.on_start_child()
  def start_extension(environment_id, extension_name),
    do: EnvironmentSupervisor.start_extension(environment_id, extension_name)

  @doc """
  Stops extension manager in runnint environment.
  Will terminate all containers/resources binded to extension.
  """
  @spec stop_extension(binary, binary) :: :ok
  def stop_extension(environment_id, extension_name),
    do: Extension.stop(environment_id, extension_name)

  @doc """
  Stops supervision tree for environment with given ID
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(id),
    do: EnvironmentsDynamicSupervisor.stop_environment(id)

  @doc """
  Checks if given environment supervisor tree is alive
  """
  @spec alive?(binary) :: boolean
  def alive?(id) do
    id
    |> EnvironmentSupervisor.via_tuple()
    |> GenServer.whereis()
    |> case do
      nil ->
        false

      pid ->
        Process.alive?(pid)
    end
  end

  @doc """
  Starts new container for given `extension_name` in running environment `id`.
  """
  @spec start_container(binary, binary, Container.t()) :: {:ok, Container.t()} | {:error, term}
  def start_container(id, extension_name, %Container{name: ""} = container),
    do: start_container(id, extension_name, %Container{container | name: Docker.random_name()})

  def start_container(id, extension_name, %Container{network: ""} = container),
    do: start_container(id, extension_name, %Container{container | network: id})

  def start_container(id, extension_name, %Container{image: image} = container) do
    with {:alive, true} <- {:alive, Extension.alive?(id, extension_name)},
         {:image, true} <- {:image, ConfigLoader.has_image?(extension_name, image)},
         {:ok, _pid} <- Extension.start_container(id, extension_name, container) do
      {:ok, container}
    else
      {:alive, _} ->
        Logger.error("Environment #{id}: No active `Extension` found to start new container")

        {:error, "failed to find environment with id #{id} & extension name: #{extension_name}"}

      {:image, _} ->
        Logger.error(
          "Environment #{id}: No image #{image} is allowed for extension #{extension_name}"
        )

        {:error, "#{image} image is not allowed for extension #{extension_name}"}

      err ->
        Logger.error(
          "Environment #{id}: failed to start container #{image} with err: #{inspect(err)}"
        )

        {:error, "failed to start image"}
    end
  end

  @doc """
  Get environment details by `id`
  """
  @spec info(binary) :: term
  def info(id) do
    case alive?(id) do
      false ->
        []

      true ->
        id
        |> EnvironmentSupervisor.get_extension_manager_supervisor()
        |> Supervisor.which_children()
        |> Enum.filter(fn {_, _, _, mods} -> mods == [Extension] end)
        |> Enum.map(fn {_, pid, :worker, _} -> pid end)
        |> Enum.map(&Extension.info/1)
        |> List.flatten()
    end
  end

  @doc """
  Load list of all available environments in system
  """
  @spec list() :: [map]
  def list() do
    # EnvironmentsDynamicSupervisor
    # |> Supervisor.which_children()
    # |> Enum.map(fn {_, pid, :supervisor, _} -> pid end)
    # |> IO.inspect()

    []
  end

  @doc """
  Force system to reload all extensions configs
  """
  @spec reload_config() :: :ok
  def reload_config(),
    do: ConfigLoader.reload()

  # Validate if all extensions are allowed to start
  defp validate_extensions([]), do: :ok

  defp validate_extensions(list) do
    result =
      list
      |> Enum.reject(&(&1 == @testchain_key))
      |> Enum.filter(fn extension_name -> ConfigLoader.get(extension_name) == nil end)

    case result do
      [] ->
        :ok

      list ->
        {:error, "Some extensions are not allowed to be started ! #{inspect(list)}"}
    end
  end

  # Get list of extension names that need to be started
  defp get_extension_names(params) when is_map(params) do
    params
    |> Map.keys()
    |> Enum.reject(&(&1 == @testchain_key))
    |> Enum.reject(&(&1 == ""))
  end
end
