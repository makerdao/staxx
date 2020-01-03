defmodule Staxx.Testchain.EVM.Implementation.Geth do
  @moduledoc """
  Geth EVM implementation

  NOTE:
  Geth is running in dev mode and some configs are hardcoded by `geth`
  They are:
   - `chain_id` - 999
   - `gas_limit` - 6_283_185

  And another issue is that accounts will be created correctly
  but balance will be set only for `coinbase` account only (first account)
  """
  use Staxx.Testchain.EVM

  alias Staxx.Testchain.AccountStore
  alias Staxx.Testchain.EVM.Implementation.Geth.Genesis
  alias Staxx.Testchain.EVM.Implementation.Geth.AccountsCreator

  require Logger

  # account password file inside docker container.
  # it will be mapped to `AccountsCreator.password_file/0`
  @password_file "/tmp/account_password"

  @impl EVM
  def start(%Config{id: id, db_path: db_path, http_port: http_port, ws_port: ws_port} = config) do
    # We have to create accounts only if we don't have any already
    accounts =
      case AccountStore.exists?(db_path) do
        false ->
          Logger.debug("#{id}: Creating accounts")

          config
          |> Map.get(:accounts)
          |> AccountsCreator.create_accounts(db_path)
          |> store_accounts(db_path)

        true ->
          Logger.info("#{id} Path #{db_path} is not empty. New accounts would not be created.")
          {:ok, list} = load_accounts(db_path)
          list
      end

    Logger.debug("#{id}: Accounts: #{inspect(accounts)}")

    unless File.exists?(Path.join(db_path, "genesis.json")) do
      :ok = write_genesis(config, accounts)
      Logger.debug("#{id}: genesis.json file created")
    end

    # Checking for existing genesis block and init if not found
    # We switched to --dev with instamining feature so right now
    # we don't need to init chain from genesis.json

    unless File.dir?(db_path <> "/geth") do
      :ok = init_chain(db_path)
    end

    Logger.debug("#{id}: starting port with geth node")

    container = %Container{
      permanent: true,
      image: Application.get_env(:testchain, :geth_docker_image),
      name: Docker.random_name(),
      description: "#{id}: Geth EVM",
      cmd: build_cmd(config, accounts),
      ports: [{http_port, http_port}, {ws_port, ws_port}],
      dev_mode: true,
      volumes: ["#{db_path}:#{db_path}", "#{AccountsCreator.password_file()}:#{@password_file}"]
    }

    {:ok, container, %{}}
  end

  @impl EVM
  def stop(_, %{port: port} = state) do
    send_command(port, "exit")
    {:ok, state}
  end

  @impl EVM
  def terminate(id, config, nil) do
    Logger.error("#{id} could not start process... Something wrong. Config: #{inspect(config)}")
    :ok
  end

  @impl EVM
  def terminate(id, _config, state) do
    Logger.debug("#{id}: Terminating... #{inspect(state)}")
    # Porcelain.Process.stop(port)
    :ok
  end

  @impl EVM
  def version(),
    do: "1.8.27"

  @impl EVM
  def get_version() do
    version()
    |> Version.parse()
    |> case do
      {:ok, version} ->
        version

      _ ->
        Logger.error("#{__MODULE__} Failed to parse version for geth")
        nil
    end
  end

  @doc """
  Path to `geth` executable in system. For generating accounts + runing `geth init`
  """
  @spec executable!() :: binary
  def executable!(),
    do: Application.get_env(:testchain, :geth_executable, "geth")

  @doc """
  Bootstrap and initialize a new genesis block.

  It will run `geth init` command using `--datadir db_path`
  NOTE: this function will break `dev` mode and should not be used with it
  """
  @spec init_chain(binary) :: :ok | {:error, term()}
  def init_chain(db_path) do
    %Container{
      permanent: false,
      image: Application.get_env(:testchain, :geth_docker_image),
      cmd: "--datadir #{db_path} init #{db_path}/genesis.json",
      volumes: ["#{db_path}:#{db_path}"]
    }
    |> Docker.run_sync()
    |> case do
      %{status: 0} ->
        Logger.debug("#{__MODULE__} geth initialized chain in #{db_path}")
        :ok

      %{status: code} ->
        Logger.error("#{__MODULE__}: Failed to run `geth init`. exited with code: #{code}")
        {:error, :init_failed}
    end
  end

  @doc """
  Execute special console command on started node.
  Be default command will be executed using HTTP JSONRPC console.

  Comamnd will be used:
  `geth --exec "${command}" attach http://localhost:${http_port}`

  Example:
  ```elixir
  iex()> Staxx.Testchain.EVM.Implementation.Geth.exec_command(8545, "eth_blockNumber")
  {:ok, 80}
  ```
  """
  @spec exec_command(binary | non_neg_integer(), binary, term()) ::
          {:ok, term()} | {:error, term()}
  def exec_command(http_port, command, params \\ nil)
      when is_binary(http_port) or is_integer(http_port) do
    "http://localhost:#{http_port}"
    |> Staxx.JsonRpc.call(command, params)
  end

  #
  # Private functions
  #

  # Writing `genesis.json` file into defined `db_path`
  defp write_genesis(
         %Config{db_path: db_path, id: id} = config,
         accounts
       ) do
    Logger.debug("#{id}: Writring genesis file to `#{db_path}/genesis.json`")

    %Genesis{
      chain_id: Map.get(config, :network_id, 999),
      accounts: accounts,
      gas_limit: Map.get(config, :gas_limit),
      period: Map.get(config, :block_mine_time, 0)
    }
    |> Genesis.write(db_path)
  end

  # Build argument list for new geth node. See `Chain.EVM.Geth.start_node/1`
  defp build_cmd(
         %Config{
           db_path: db_path,
           network_id: network_id,
           http_port: http_port,
           ws_port: ws_port,
           output: output,
           gas_limit: gas_limit
         },
         accounts
       ) do
    cmd = [
      "--datadir #{db_path}",
      "--networkid #{network_id}",
      # Disabling network, node is private !
      "--maxpeers=0",
      "--port=0",
      "--nousb",
      "--ipcdisable",
      "--mine",
      "--minerthreads=1",
      "--rpc",
      "--rpcport #{http_port}",
      "--rpcapi admin,personal,eth,miner,debug,txpool,net,web3,db,ssh",
      "--rpcaddr=\"0.0.0.0\"",
      "--rpccorsdomain=\"*\"",
      "--rpcvhosts=\"*\"",
      "--ws",
      "--wsport #{ws_port}",
      "--wsorigins=\"*\"",
      "--gasprice=\"2000000000\"",
      "--targetgaslimit=\"#{gas_limit}\"",
      "--password=#{@password_file}",
      get_etherbase(accounts),
      get_unlock(accounts)
      # "console"
      # get_output(output)
    ]

    # If version is greater than 1.8.17 need to add additional flag
    case Version.compare(get_version(), "1.8.27") do
      :gt ->
        cmd ++ ["--allow-insecure-unlock"]

      _ ->
        cmd
    end
    |> Enum.join(" ")
  end

  #####
  # List of functions generating CLI options
  #####

  # combine list of accounts to unlock `--unlock 0x....,0x.....`
  defp get_unlock([]), do: ""

  defp get_unlock(list) do
    res =
      list
      |> Enum.map(fn %Account{address: address} -> address end)
      |> Enum.join("\",\"")

    "--unlock=\"#{res}\""
  end

  # get etherbase account. it's just 1st address from list
  defp get_etherbase([]), do: ""

  defp get_etherbase([%Account{address: address} | _]),
    do: "--etherbase=#{address}"

  # Get path for logging
  defp get_output(""), do: "2>> /dev/null"
  defp get_output(path) when is_binary(path), do: "2>> #{path}"
  # Ignore in any other case
  defp get_output(_), do: "2>> /dev/null"

  #####
  # End of list
  #####

  # Send command to port
  # This action will send command directly to started node console.
  # Without attaching.
  # If you will send breacking command - node might exit

  defp send_command(port, command) do
    Porcelain.Process.send_input(port, command <> "\n")
    :ok
  end
end
