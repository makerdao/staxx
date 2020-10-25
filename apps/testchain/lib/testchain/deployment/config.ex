defmodule Staxx.Testchain.Deployment.Config do
  @moduledoc """
  Configuration for deployment process
  """

  # github deployment scripts URL
  @deployment_scripts_repo_url "https://github.com/makerdao/dss-deploy-scripts"

  @type t :: %__MODULE__{
          evm_pid: GenServer.server(),
          request_id: binary,
          scope_id: binary,
          step_id: pos_integer,
          rpc_url: binary,
          coinbase: binary,
          gas_limit: pos_integer,
          git_ref: binary,
          git_url: binary
        }

  @enforce_keys [:evm_pid, :scope_id]
  defstruct evm_pid: nil,
            request_id: "",
            scope_id: "",
            step_id: 0,
            rpc_url: "",
            coinbase: "",
            gas_limit: "17000000",
            git_ref: Application.get_env(:instance, :default_deployment_scripts_git_ref),
            git_url: @deployment_scripts_repo_url
end
