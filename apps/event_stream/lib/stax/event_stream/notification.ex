defmodule Staxx.EventStream.Notification do
  @moduledoc """
  Default notification structure.

  For example on chain start system should fire event `:started`.
  It will have such structure:

  ```elixir
  %Staxx.EventStream.Notification{
    id: "15054686724791906538", 
    event: :started,
    data: %{
      accounts: ["0x51ef0fe1fe60af27f400ab42ddc9a6b99b277d38"],
      coinbase: "0x51ef0fe1fe60af27f400ab42ddc9a6b99b277d38",
      rpc_url: "http://localhost:8545",
      ws_url: "ws://localhost:8546"
    }
  }
  ```
  """

  alias Staxx.EventStream

  @typedoc """
  Event type that should be sent by chain implementation
  """
  @type event ::
          :error
          | :started
          | :status_changed
          | binary

  @typedoc """
  Default Notification structure.
  Consist of:
   - `id` - Stack/Testchain id
   - `event` - Event that happened
   - `data` - Map with any data you need to pass with event
  """
  @type t :: %__MODULE__{
          id: binary,
          event: event(),
          data: map()
        }

  @enforce_keys [:id, :event]
  defstruct id: nil, event: nil, data: %{}

  @doc """
  Send notification to event bus
  """
  @spec notify(%__MODULE__{}) :: :ok
  def notify(%__MODULE__{} = notification),
    do: EventStream.dispatch(notification)

  @doc """
  Send custom notification to event bus
  """
  @spec notify(binary, event(), term) :: :ok
  def notify(id, event, data \\ %{}) do
    %__MODULE__{id: id, event: event, data: data}
    |> notify()
  end
end

defimpl Jason.Encoder, for: Staxx.EventStream.Notification do
  def encode(value, opts) do
    value
    |> Map.from_struct()
    |> Jason.Encode.map(opts)
  end
end
