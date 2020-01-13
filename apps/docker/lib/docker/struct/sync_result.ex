defmodule Staxx.Docker.Struct.SyncResult do
  @moduledoc """
  Docker `run_sync/1` result structure
  """
  @type t :: %__MODULE__{
          status: pos_integer,
          data: binary,
          err: nil | term
        }

  @derive Jason.Encoder
  defstruct status: 0, data: "", err: nil
end
