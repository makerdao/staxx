defmodule DeploymentScope do
  @moduledoc """
  DeploymentScope is responsible for  aggregation of chain + stacks in one scope
  It handle and manage starting chain/stacks in correct order and validation
  """

  require Logger

  alias Proxy.Chain.ChainHelper
  alias DeploymentScope.ScopesSupervisor
  alias DeploymentScope.Scope.SupervisorTree

  def test() do
    config = %{
      "type" => "geth",
      "accounts" => 1,
      "block_mine_time" => 0,
      "clean_on_stop" => false,
      "step_id" => 0
    }

    params = %{
      "testchain" => %{
        "config" => config,
        "deps" => []
      },
      "helloworld" => %{
        "config" => %{},
        "deps" => ["testchain"]
      }
    }

    %{id: id} =
      chain_config =
      config
      |> ChainHelper.chain_config_from_payload()
      |> Proxy.new_chain_config!()

    stacks = Map.drop(params, ["testchain"])

    {id, chain_config, stacks}
  end

  def start_test() do
    test()
    |> ScopesSupervisor.start_scope()
  end

  @doc """
  Start new deployment scope using given configuration
  """
  @spec start(map) :: {:ok, binary} | {:error, term}
  def start(%{"testchain" => %{"config" => %{"id" => id}}} = params) do
    stacks = Map.drop(params, ["testchain"])

    Logger.debug(fn ->
      """
      Starting deployment scope with existing chain #{id}
      Config:
      #{inspect(stacks, pretty: true)}
      """
    end)

    start(id, id, stacks)
  end

  def start(%{"testchain" => %{"config" => config}} = params) do
    %{id: id} =
      chain_config =
      config
      |> ChainHelper.chain_config_from_payload()
      |> Proxy.new_chain_config!()

    stacks = Map.drop(params, ["testchain"])

    Logger.debug(fn ->
      """
      Starting deployment scope with new chain
      Chain configuration:
      #{inspect(chain_config, pretty: true)}

      Config:
      #{inspect(stacks, pretty: true)}
      """
    end)

    start(id, chain_config, stacks)
  end

  @doc """
  Start supervision tree for new deployment scope
  """
  @spec start(binary, binary | map, map) :: {:ok, binary} | {:error, term}
  def start(id, chain_config, stacks) when is_binary(id) do
    modules = Stacks.get_stack_names(stacks)
    Logger.debug("Starting new deployment scope with modules: #{inspect(modules)}")

    with :ok <- Stacks.validate(modules),
         {:ok, pid} <- ScopesSupervisor.start_scope({id, chain_config, stacks}) do
      Logger.debug("Started chain supervisor tree #{inspect(pid)} for stack #{id}")
      {:ok, id}
    else
      {:error, err} ->
        Logger.error("Failed to start deployment scope #{inspect(err)}")
        {:error, err}

      err ->
        Logger.error("Failed to start deployment scope #{inspect(err)}")
        {:error, err}
    end
  end

  def start(_, _),
    do: {:error, "wrong chain config"}

  def stop(id) do
    id
    |> SupervisorTree.via_tuple()
    |> Supervisor.stop(:normal)
  end
end
