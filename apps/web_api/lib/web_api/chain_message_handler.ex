defmodule WebApi.ChainMessageHandler do
  @moduledoc """
  Main process that will handle all messages from different chains.
  Because this process will have name all communication to it should be
  done using it's name, to avoid restart and change pid issue.
  """
  use GenServer

  require Logger

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc false
  def init(_) do
    {:ok, []}
  end

  # Handle Notification from chain
  def handle_info(%{id: id, event: event, data: data}, state) do
    # Broadcasting event to direct channel
    response =
      case data do
        %_{} ->
          Map.from_struct(data)

        %{__struct__: _} ->
          Map.from_struct(data)

        %{} ->
          data

        other ->
          %{data: other}
      end

    if event in [:started, :error] do
      WebApiWeb.Endpoint.broadcast("api", to_string(event), response)
    end

    WebApiWeb.Endpoint.broadcast("chain:#{id}", to_string(event), response)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Unknown message: #{inspect(msg)}")
    {:noreply, state}
  end
end
