defmodule Staxx.WebApi.ChainMessageHandler do
  @moduledoc """
  Main process that will handle all messages from different chains.
  Because this process will have name all communication to it should be
  done using it's name, to avoid restart and change pid issue.
  """
  use GenServer

  require Logger
  alias Staxx.EventStream
  alias Staxx.WebApiWeb.Endpoint

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc false
  def init(_) do
    :ok = EventStream.subscribe({__MODULE__, [".*"]})
    {:ok, []}
  end

  def process({topic, id}),
    do: GenServer.cast(__MODULE__, {topic, id})

  def handle_cast({topic, id}, state) do
    case EventStream.fetch_event_data({topic, id}) do
      %{id: _id, event: _event, data: _data} = msg ->
        handle_info(msg, state)
        EventStream.mark_as_completed({__MODULE__, topic, id})
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  # Handle Notification from chain
  def handle_info(%{id: id, event: event, data: data}, state) do
    # Broadcasting event to direct channel
    response =
      case data do
        %{} ->
          data

        other ->
          %{data: other}
      end

    if event in [:started, :error] do
      Endpoint.broadcast("api", to_string(event), response)
    end

    Endpoint.broadcast("chain:#{id}", to_string(event), response)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Unknown message: #{inspect(msg)}")
    {:noreply, state}
  end
end
