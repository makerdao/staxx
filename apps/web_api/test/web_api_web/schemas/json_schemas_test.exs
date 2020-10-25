defmodule Staxx.WebApiWeb.JSONSchemasTest do
  use ExUnit.Case

  alias Staxx.Instance
  alias Staxx.WebApiWeb.Schemas.TestchainSchema

  @moduletag :api

  @moduletag :schema
  describe "Data should pass schema validation" do
    test "There are properties described in schema" do
      data = %{
        "id" => Faker.String.base64(),
        "title" => Faker.Name.name()
      }

      assert :ok == TestchainSchema.validate(data)
    end

    test "There are testchain data in property" do
      data = %{
        Instance.testchain_key() => %{
          "id" => Faker.String.base64(),
          "title" => Faker.Name.name()
        }
      }

      assert :ok == TestchainSchema.validate_with_payload(data)
    end

    test "Empty testchain data in property" do
      data = %{
        Instance.testchain_key() => %{}
      }

      assert :ok == TestchainSchema.validate_with_payload(data)
    end
  end

  describe "Data should not pass schema validation" do
    test "Property is not in schema" do
      data = %{
        "somefield" => Faker.String.base64()
      }

      assert {:error, _} = TestchainSchema.validate(data)
    end

    test "Incorrect payload" do
      data = %{"somefield" => Faker.random_between(0, 100)}
      assert {:error, _} = TestchainSchema.validate_with_payload(data)
      assert {:error, _} = TestchainSchema.validate_with_payload(%{})
      assert {:error, _} = TestchainSchema.validate_with_payload(nil)
    end
  end
end
