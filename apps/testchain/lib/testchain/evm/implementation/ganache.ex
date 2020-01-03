defmodule Staxx.Testchain.EVM.Implementation.Ganache do
  @moduledoc """
  Ganache EVM implementation
  """
  use Staxx.Testchain.EVM

  # JSON-RPC port
  @http_port 8545

  @impl EVM
  def start(%Config{id: id, accounts: amount, db_path: db_path} = config) do
    Logger.debug("#{id}: Starting ganache-cli")

    accounts =
      case AccountStore.exists?(db_path) do
        false ->
          amount
          |> generate_accounts()
          |> store_accounts(db_path)

        true ->
          {:ok, list} = load_accounts(db_path)
          list
      end

    container = %Container{
      permanent: true,
      image: docker_image(),
      name: Docker.random_name(),
      description: "#{id}: Ganache EVM",
      cmd: build_command(config, accounts),
      ports: [@http_port],
      # dev_mode: true,
      volumes: ["#{db_path}:#{db_path}"]
    }

    {:ok, container, %{}}
  end

  @impl EVM
  def pick_ports([{http_port, @http_port}], _),
    do: {http_port, http_port}

  def pick_ports(_, _),
    do: raise(ArgumentError, "Wrong input ports for Ganache EVM")

  @impl EVM
  def docker_image(),
    do: Application.get_env(:testchain, :ganache_docker_image)

  # Build command for starting ganache-cli
  defp build_command(
         %Config{
           db_path: db_path,
           network_id: network_id,
           block_mine_time: block_mine_time,
           gas_limit: gas_limit
         },
         accounts
       ) do
    [
      # Sorry but this **** never works as you expect so I have to wrap it into "killer" script
      # Otherwise after application will be terminated - ganache still will be running
      "--noVMErrorsOnRPCResponse",
      "-i #{network_id}",
      "-p #{@http_port}",
      "--db #{db_path}",
      "--gasLimit #{gas_limit}",
      inline_accounts(accounts),
      get_block_mine_time(block_mine_time)
    ]
    |> Enum.join(" ")
  end

  defp generate_accounts(number) do
    0..number
    |> Enum.map(fn _ -> Account.new() end)
  end

  defp inline_accounts(accounts) do
    accounts
    |> Enum.map(fn %Account{priv_key: key, balance: balance} ->
      "--account=\"0x#{key},#{balance}\""
    end)
    |> Enum.join(" ")
  end

  #####
  # List of functions generating CLI options
  #####

  # get params for block mining period
  defp get_block_mine_time(0), do: ""

  defp get_block_mine_time(time) when is_integer(time) and time > 0,
    do: "--blockTime #{time}"

  defp get_block_mine_time(_), do: ""

  #####
  # End of list
  #####
end
