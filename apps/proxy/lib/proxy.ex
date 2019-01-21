defmodule Proxy do
  @moduledoc """
  Proxy service functions
  """

  alias Proxy.ExChain
  alias Proxy.Chain.Worker
  alias Proxy.Chain.Supervisor

  @doc """
  Start new/existing chain
  """
  @spec start(binary | map(), nil | pid) :: {:ok, binary} | {:error, term()}
  def start(id_or_config, pid \\ nil)

  def start(id, pid) when is_binary(id) do
    case Supervisor.start_chain(id, :existing, pid) do
      :ok ->
        {:ok, id}

      _ ->
        {:error, "failed to start chain"}
    end
  end

  def start(config, pid) when is_map(config) do
    id =
      with nil <- Map.get(config, :id),
           do: ExChain.unique_id()

    res =
      config
      |> Map.put(:id, id)
      |> Map.put(:clean_on_stop, false)
      |> Supervisor.start_chain(:new, pid)

    case res do
      {:ok, _} ->
        {:ok, id}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Terminate chain
  """
  @spec stop(binary) :: :ok
  def stop(id) do
    id
    |> Worker.get_pid()
    |> GenServer.cast(:stop)
  end
end
