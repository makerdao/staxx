defmodule Staxx.DeploymentScope.Deployment.Worker do
  @moduledoc """
  Wroker that will controll deployment process flow.
  It will spawn new deployment worker (docker container) with all reaquired info
  and will handle deployment results.

  Required information for deployment:
  - request id
  - deploy step_id (scenario_id)
  - deploy scripts repo url
  - deploy scripts tag/branch
  - staxx url (where to send results)
  - chain details (coinbase, gas limit, rpc_url)

  """
  use GenServer

  alias Staxx.DeploymentScope.Deployment.BaseApi
  alias Staxx.Docker.Struct.Container

  # github deployment scripts URL
  @deployment_scripts_repo_url "https://github.com/makerdao/dss-deploy-scripts"

  def start_link() do
  end

  def init() do
  end

  defp build_container(stack_id, step_id, rpc_url, coinbase, tag) do
    %Container{
      # it will terminate and we don't need to fail on it
      permanent: false,
      image: docker_image(),
      network: stack_id,
      volumes: ["nix-db:/nix"],
      env: %{
        "REQUEST_ID" => BaseApi.random_id(),
        "DEPLOY_ENV" => chain_env(rpc_url, coinbase),
        "REPO_URL" => @deployment_scripts_repo_url,
        "REPO_REF" => tag,
        "SCENARIO_NR" => step_id,
        "TCD_GATEWAY" => "host=#{host()}"
      }
    }
  end

  # Combine deployment ENV vars for chain
  defp chain_env(rpc_url, coinbase) do
    %{
      "ETH_RPC_URL" => rpc_url,
      "ETH_FROM" => coinbase,
      "ETH_RPC_ACCOUNTS" => "yes",
      "ETH_GAS" => "17000000"
    }
    |> Poison.encode!()
  end

  defp host(),
    do: Application.get_env(:deployment_scope, :host, "host.docker.internal")

  defp docker_image(),
    do: Application.get_env(:deployment_scope, :deployment_worker_image)
end
