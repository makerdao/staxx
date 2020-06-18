defmodule Staxx.WebApiWeb.Schemas.DockerSchema do
  @moduledoc """
  Module to validare Docker container related data.
  """
  use Staxx.WebApiWeb.JSONSchemaValidator

  @schema_name "docker.schema.json"

  @doc """
  Returns json schema map.
  """
  @spec json_schema :: map()
  def json_schema(), do: json_schema_name() |> read_from_schema!()

  @doc """
  Returns `"docker.schema.json"` schema name.
  """
  @spec json_schema_name :: binary()
  def json_schema_name(), do: @schema_name
end
