defmodule Staxx.WebApiWeb.Schemas.TestchainSchema do
  @moduledoc """
  Module to validate Testchain related json data.
  """
  use Staxx.WebApiWeb.JSONSchemaValidator

  @schema_name "testchain.schema.json"

  @doc """
  Validates testchain data inside some structure with the property "testchain".
  Returns error for empty, nil, or for map without "testchain" property.
  """
  @spec validate_with_payload(map) :: :ok | {:error, term()}
  def validate_with_payload(%{"testchain" => data}), do: validate(data)
  def validate_with_payload(%{}), do: {:error, "Empty or incorrect payload."}
  def validate_with_payload(_), do: validate_with_payload(%{})

  @doc """
  Returns json schema map.
  """
  @spec json_schema :: map()
  def json_schema(), do: json_schema_name() |> read_from_schema!()

  @doc """
  Returns `"testchain.schema.json"` schema name.
  """
  @spec json_schema_name :: binary()
  def json_schema_name(), do: @schema_name
end
