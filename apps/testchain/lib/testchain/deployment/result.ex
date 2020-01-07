defmodule Staxx.Testchain.Deployment.Result do
  @moduledoc """
  Default sctructure for deployment result.
  """

  @type t :: %__MODULE__{
          request_id: binary,
          git_ref: binary,
          step_id: binary,
          result: map
        }

  @derive Jason.Encoder
  defstruct request_id: "",
            git_ref: "",
            step_id: "",
            result: %{}
end
