defmodule Staxx.WebApiWeb.JSONSchemaCache do
  @moduledoc """
  JSONSchemaCache caches resolved json schemas. Uses Agent.
  """
  use Agent
  @spec start_link(map()) :: {:error, any} | {:ok, pid}
  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @doc """
  Puts schema with given name in to cache.
  Returns schema.
  """
  @spec put_schema(map(), any) :: map()
  def put_schema(schema, name) do
    Agent.update(__MODULE__, fn state -> Map.put(state, name, schema) end)
    schema
  end

  @doc """
  Returns schema by given name from cache.
  Returns nil if schema by given name desn't exist.
  """
  @spec get_schema(any) :: map()
  def get_schema(name), do: Agent.get(__MODULE__, fn state -> Map.get(state, name) end)

  @doc """
  Checks if schema by given is already cached.
  """
  @spec cached?(any) :: boolean()
  def cached?(name), do: Agent.get(__MODULE__, fn state -> Map.has_key?(state, name) end)

  @doc """
  Cleans cache.
  """
  @spec clean :: :ok
  def clean(), do: Agent.update(__MODULE__, fn _ -> %{} end)
end
