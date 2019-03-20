defmodule Proxy.Chain.Worker.State do
  @moduledoc """
  Default Worker state

  Worker has it's own statuses a bit different to ExTestchain

  When new worker is spawning it's status is set to `:initializing` then flow is this:
  `:initializing` -> `:ready` -> `:terminating` -> `:terminated`
  So chain is fully ready only when status is set to `:ready`
  In case of failure status will be set to `:failed`
  """

  alias Proxy.Chain.Storage.Record
  alias Proxy.Chain.Worker.Notification

  @type status :: :initializing | :ready | :terminating | :terminated | :locked | :failed

  @type t :: %__MODULE__{
          id: binary,
          node: node(),
          start: :new | :existing,
          status: status,
          notify_pid: pid() | nil,
          chain_status: atom(),
          deploy_step_id: 0..9
        }

  defstruct id: nil,
            node: nil,
            start: :new,
            status: :initializing,
            notify_pid: nil,
            chain_status: :none,
            deploy_step_id: 0

  @doc """
  Update node for state and return updated state
  """
  @spec node(t(), node()) :: t()
  def node(%__MODULE__{} = state, node), do: %__MODULE__{state | node: node}

  @spec status(t(), status()) :: t()
  def status(%__MODULE__{} = state, status),
    do: %__MODULE__{state | status: status}

  @spec chain_status(t(), atom) :: t()
  def chain_status(%__MODULE__{} = state, chain_status),
    do: %__MODULE__{state | chain_status: chain_status}

  @doc """
  Send notification about chain to `notify_pid`.
  If no `notify_pid` config exist into state - `:ok` will be returned
  """
  @spec notify(t(), binary | atom, term()) :: t()
  def notify(%__MODULE__{id: id, notify_pid: pid} = state, event, data \\ %{}) do
    notification = %Notification{id: id, event: event, data: data}

    if pid do
      send(pid, notification)
    end

    Proxy.EventBus.Broadcaster.notify({"chain.#{id}", notification})
    state
  end

  @doc """
  Store state into DB. Will call Storage to store worker
  """
  @spec store(t()) :: t()
  def store(%__MODULE__{} = state) do
    state
    |> Record.from_state()
    |> Record.store()

    state
  end
end
