defmodule Proxy.Chain.Worker.State do
  @moduledoc """
  Default Worker state
  """

  defstruct id: nil,
            start: :new,
            chain_status: :none,
            status: :starting,
            config: nil,
            notify_pid: nil,
            details: nil,
            deploy_data: nil,
            deploy_step: nil,
            deploy_hash: nil
end
