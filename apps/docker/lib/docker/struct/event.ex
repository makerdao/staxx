defmodule Staxx.Docker.Struct.Event do
  @moduledoc """
  Default docker event representation
  """

  @type t :: %__MODULE__{
          id: binary,
          name: binary,
          event: binary,
          container: binary,
          attributes: map
        }

  @derive Jason.Encoder
  defstruct id: "",
            name: "",
            event: "",
            container: "",
            attributes: %{}
end
