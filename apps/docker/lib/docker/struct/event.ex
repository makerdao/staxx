defmodule Docker.Struct.Event do
  @moduledoc """
  Default docker event representation
  """

  @type t :: %__MODULE__{
          id: binary,
          event: binary,
          container: binary,
          attributes: map
        }

  @derive Jason.Encoder
  defstruct id: "",
            event: "",
            container: "",
            attributes: %{}
end
