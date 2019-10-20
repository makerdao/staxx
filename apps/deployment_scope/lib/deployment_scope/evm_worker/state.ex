defmodule Staxx.DeploymentScope.EVMWorker.State do
  @moduledoc """
  Default chain process state

  Chain process has it's own statuses a bit different to ExTestchain

  When new chain process is spawning it's status is set to `:initializing` then flow is this:
  `:initializing` -> `:ready` -> `:terminating` -> `:terminated`
  So chain is fully ready only when status is set to `:ready`
  In case of failure status will be set to `:failed`
  """

  alias Staxx.DeploymentScope.EVMWorker.Storage.Record
  alias Staxx.DeploymentScope.EVMWorker.Notification

  @type status :: :initializing | :ready | :terminating | :terminated | :locked | :failed

  @type t :: %__MODULE__{
          id: binary,
          node: node(),
          start_type: :new | :existing,
          status: status,
          notify_pid: pid() | nil,
          chain_status: atom(),
          deploy_tag: nil | binary,
          deploy_step_id: 0..9,
          deploy_pid: pid() | nil
        }

  defstruct id: nil,
            node: nil,
            start_type: :new,
            status: :initializing,
            notify_pid: nil,
            chain_status: :none,
            deploy_tag: nil,
            deploy_step_id: 0,
            deploy_pid: nil

  @doc """
  Update node for state and return updated state
  """
  @spec node(t(), node()) :: t()
  def node(%__MODULE__{} = state, node), do: %__MODULE__{state | node: node}

  @doc """
  Set status for state and return updated state
  """
  @spec status(t(), status()) :: t()
  def status(%__MODULE__{} = state, status),
    do: %__MODULE__{state | status: status}

  @doc """
  Set chain status for state and return updated state
  """
  @spec chain_status(t(), atom) :: t()
  def chain_status(%__MODULE__{} = state, chain_status),
    do: %__MODULE__{state | chain_status: chain_status}

  @doc """
  Set deployment process id for state and return updated state
  """
  @spec deploy_pid(t(), pid) :: t()
  def deploy_pid(%__MODULE__{} = state, pid),
    do: %__MODULE__{state | deploy_pid: pid}

  @doc """
  Send notification about chain to `notify_pid`.
  Notification will be send to `notify_pid` if it's exist
  And to global event bus
  """
  @spec notify(t(), binary | atom, term()) :: t()
  def notify(%__MODULE__{id: id, notify_pid: pid} = state, event, data \\ %{}) do
    notification = %Notification{id: id, event: event, data: data}

    if pid do
      send(pid, notification)
    end

    Notification.send_to_event_bus(notification)
    state
  end

  @doc """
  Store state into DB. Will call Storage to store chain details
  """
  @spec store(t()) :: t()
  def store(%__MODULE__{} = state) do
    state
    |> Record.from_state()
    |> Record.store()

    state
  end
end
