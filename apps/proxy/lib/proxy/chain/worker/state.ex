defmodule Proxy.Chain.Worker.State do
  @moduledoc """
  Default Worker state
  """

  @type t :: %__MODULE__{
          id: binary,
          node: node(),
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
            node: nil,
            start: :new,
            status: :starting,
            config: nil,
            notify_pid: nil,
            chain_status: :none,
            chain_details: nil,
            deploy_data: nil,
            deploy_step: nil,
            deploy_hash: nil

  @doc """
  Update node for state and return updated state
  """
  @spec node(Proxy.Chain.Worker.State.t(), node()) :: Proxy.Chain.Worker.State.t()
  def node(%__MODULE__{} = state, node), do: %__MODULE__{state | node: node}

  @doc """
  Send notification about chain to `notify_pid`.
  If no `notify_pid` config exist into state - `:ok` will be returned
  """
  @spec notify(Proxy.Chain.Worker.State.t(), binary | atom, term()) :: :ok
  def notify(state, event, data \\ %{})

  def notify(%__MODULE__{notify_pid: nil}, _, _), do: :ok

  def notify(%__MODULE__{id: id, notify_pid: pid}, event, data),
    do: send(pid, %{id: id, event: event, data: data})
end
