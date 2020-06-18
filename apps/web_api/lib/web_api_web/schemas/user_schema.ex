defmodule Staxx.WebApiWeb.Schemas.UserSchema do
  @moduledoc """
  Module to validate User model related json data.
  """
  use Staxx.WebApiWeb.JSONSchemaValidator

  @schema_name "user.schema.json"

  @doc """
  Returns `"testchain.schema.json"` schema name.
  """
  @spec json_schema_name :: binary()
  def json_schema_name(), do: @schema_name

  @doc """
  Returns json schema map.
  """
  @spec json_schema :: map
  def json_schema(), do: json_schema_name() |> read_from_schema!()
end
