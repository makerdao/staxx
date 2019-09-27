defmodule Staxx.DeploymentScope.UserScope do
  @moduledoc """
  Helper module for mapping between user <-> deployment_scope
  """
  use GenServer

  require Logger

  @table "user_deployment_scope"

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    :dets.open_file(table(), type: :bag)
    Logger.debug(fn -> "Started new DETS table for mapping user <-> scope" end)
    {:ok, @table}
  end

  @doc false
  def terminate(_reason, _state) do
    Logger.debug(fn -> "Stopping DETS table for mapping user -> scope" end)
    :dets.close(table())
  end

  @doc false
  def handle_call({:map, scope_id, email}, _, state) do
    case :dets.insert(table(), {email, scope_id}) do
      :ok ->
        {:reply, :ok, state}

      {:error, err} ->
        {:reply, {:error, err}, state}
    end
  end

  @doc false
  def handle_call({:by_email, email}, _, state) do
    res =
      table()
      |> :dets.lookup(email)
      |> Enum.map(fn {_, id} -> id end)

    {:reply, res, state}
  end

  @doc false
  def handle_cast({:unmap, scope_id, email}, state) do
    :dets.delete_object(table(), {email, scope_id})
    {:noreply, state}
  end

  @doc false
  def handle_cast({:unmap, scope_id}, state) do
    table()
    |> :dets.match_object({:"$1", scope_id})
    |> Enum.map(fn obj -> :dets.delete_object(table(), obj) end)

    {:noreply, state}
  end

  @doc """
  Maps given deployment scope with emial address
  """
  @spec map(binary, binary) :: :ok | {:error, term()}
  def map(scope_id, email),
    do: GenServer.call(__MODULE__, {:map, scope_id, email})

  @doc """
  Remove mapping between given deployment scope and user
  This function ignores any error if no mapping is found
  """
  @spec unmap(binary, binary) :: :ok
  def unmap(scope_id, email),
    do: GenServer.cast(__MODULE__, {:unmap, scope_id, email})

  @doc """
  Remove mapping between given deployment scope and user
  This function ignores any error if no mapping is found
  """
  @spec unmap(binary) :: :ok
  def unmap(scope_id),
    do: GenServer.cast(__MODULE__, {:unmap, scope_id})

  @doc """
  List all deployment scopes that are mapped to given user
  """
  @spec list_by_email(binary) :: [binary]
  def list_by_email(email),
    do: GenServer.call(__MODULE__, {:by_email, email})

  # get path to DETS file for storage chain process
  defp db_path() do
    :proxy
    |> Application.get_env(:dets_db_path)
    |> Path.expand()
  end

  # Get full table path
  defp table() do
    db_path()
    |> Path.join(@table)
    |> String.to_atom()
  end
end
