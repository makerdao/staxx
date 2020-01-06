defmodule Staxx.Testchain.EVM.State do
  @moduledoc """
  Default structure for handling state into any EVM implementation

  Consist of this properties:
   - `status` - Chain status
   - `version` - EVM version
   - `http_port` - HTTP JSONRPC port. In case of `nil` - port will be randomly assigned (Default: `nil`)
   - `ws_port` - WS JSONRPC port, in case of `nil` - port will be randomly assigned
    (for ganache it will be ignored and `http_port` will be used) (Default: `nil`)
   - `task` - Task scheduled for execution after chain stop
   - `container_pid` - EVM container pid in system.
   - `config` - default configuration for chain. Not available in implemented callback functions
   - `internal_state` - state for chain implementation

  `internal_state` - will be passed as state for all implemented callback functions
  """

  alias Staxx.Testchain.EVM
  alias Staxx.Testchain.EVM.Config

  @type t :: %__MODULE__{
          status: EVM.status(),
          http_port: non_neg_integer() | nil,
          ws_port: non_neg_integer() | nil,
          version: Version.t() | nil,
          task: EVM.scheduled_task(),
          config: Config.t(),
          container_pid: pid,
          internal_state: term()
        }
  @enforce_keys [:config]
  defstruct status: :none,
            http_port: nil,
            ws_port: nil,
            version: nil,
            task: nil,
            config: nil,
            container_pid: nil,
            internal_state: nil

  @doc """
  Set new scheduled task value
  """
  @spec task(t(), EVM.scheduled_task()) :: t()
  def task(%__MODULE__{} = state, task), do: %__MODULE__{state | task: task}
end
