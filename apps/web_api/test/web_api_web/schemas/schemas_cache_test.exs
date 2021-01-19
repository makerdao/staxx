defmodule Staxx.WebApiWeb.SchemasCacheTest do
  use ExUnit.Case
  alias Staxx.WebApiWeb.Schemas.TestchainSchema
  alias Staxx.WebApiWeb.JSONSchemaCache
  @moduletag :schema

  setup do
    JSONSchemaCache.clean()
    :ok
  end

  describe "Schemas cache test" do
    test "Cache should return false if there is no schema with given name" do
      assert false == JSONSchemaCache.cached?(Faker.String.base64())
    end

    test "Cache should keep schema after first validate" do
      data = %{
        "id" => Faker.String.base64(),
        "title" => Faker.Person.name()
      }

      schema_name = TestchainSchema.json_schema_name()
      assert false == JSONSchemaCache.cached?(schema_name)
      assert :ok == TestchainSchema.validate(data)
      assert true == JSONSchemaCache.cached?(schema_name)
    end
  end
end
