defmodule Staxx.Testchain.EVM.State do
  @moduledoc """
  Default structure for handling state into any EVM implementation

  Consist of this properties:
   - `status` - Chain status
   - `locked` - Identify if chain is locked or not
   - `task` - Task scheduled for execution after chain stop
   - `config` - default configuration for chain. Not available in implemented callback functions
   - `internal_state` - state for chain implementation

  `internal_state` - will be passed as state for all implemented callback functions
  """

  alias Staxx.Testchain.EVM
  alias Staxx.Testchain.EVM.{Config, Notification}
  alias Staxx.Storage

  @type t :: %__MODULE__{
          status: EVM.status(),
          locked: boolean(),
          version: Version.t() | nil,
          task: EVM.scheduled_task(),
          config: Config.t(),
          internal_state: term()
        }
  @enforce_keys [:config]
  defstruct status: :none,
            locked: false,
            version: nil,
            task: nil,
            config: nil,
            internal_state: nil

  @doc """
  Set internal state
  """
  @spec internal_state(t(), term()) :: t()
  def internal_state(%__MODULE__{} = state, internal_state),
    do: %__MODULE__{state | internal_state: internal_state}

  @doc """
  Set new status to evm state.
  And if config is passed and `notify_pid` is set - notification will be sent.

  ```elixir
  %Staxx.ExChain.EVM.Notification{id: config.id, event: :status_changed, status}
  ```

  And if chain should not be cleaned after stop - status will be stored using `Storage.store/2`
  """
  @spec status(t(), EVM.status(), Config.t()) :: t()
  def status(%__MODULE__{} = state, status, config \\ %{}) do
    Notification.send(config, Map.get(config, :id), :status_changed, status)

    unless Map.get(config, :clean_on_stop, true) do
      Storage.store(config, status)
    end

    %__MODULE__{state | status: status}
  end

  @doc """
  Set locked to true and send notification that chain was locked.
  Notification will be sent only if config is passed and `notify_pid` is set

  In case of chain is already locked - nothing will happen
  """
  @spec locked(t(), boolean, Config.t()) :: t()
  def locked(%__MODULE__{} = state, locked, config \\ %{}) do
    case locked do
      true ->
        Notification.send(config, Map.get(config, :id), :locked)

      false ->
        Notification.send(config, Map.get(config, :id), :unlocked)
    end

    %__MODULE__{state | locked: locked}
  end

  @doc """
  Set new scheduled task value
  """
  @spec task(t(), EVM.scheduled_task()) :: t()
  def task(%__MODULE__{} = state, task), do: %__MODULE__{state | task: task}

  @doc """
  Set new config into state
  """
  @spec config(t(), Config.t()) :: t()
  def config(%__MODULE__{} = state, %Config{} = config),
    do: %__MODULE__{state | config: config}
end
