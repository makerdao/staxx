defmodule Proxy.Chain.Worker.State do
  @moduledoc """
  Default Worker state
  """

  defstruct id: nil, action: :new, status: :none, config: nil, notify_pid: nil
end
