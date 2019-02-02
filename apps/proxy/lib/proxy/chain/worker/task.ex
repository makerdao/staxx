defmodule Proxy.Chain.Worker.Task do
  @moduledoc """
  Task that should be performed on chain instance after it starts
  """

  @type action :: :deploy

  @type t :: %__MODULE__{
          action: Proxy.Chain.Worker.Task.action(),
          data: term()
        }

  defstruct action: :none, data: nil
end
