defmodule Proxy.Chain.Worker.State do
  @moduledoc """
  Default Worker state
  """

  @type t :: %__MODULE__{
          id: binary,
          start: :new | :existing,
          status: Proxy.Chain.Worker.status(),
          config: map(),
          notify_pid: pid() | nil,
          chain_status: atom(),
          chain_details: map(),
          deploy_data: map(),
          deploy_step: 0..9,
          deploy_hash: binary
        }

  defstruct id: nil,
            start: :new,
            status: :starting,
            config: nil,
            notify_pid: nil,
            chain_status: :none,
            chain_details: nil,
            deploy_data: nil,
            deploy_step: nil,
            deploy_hash: nil
end
