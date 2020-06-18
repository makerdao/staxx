defmodule Staxx.WebApiWeb.JSONSchemaValidator do
  @moduledoc """
  JSONSchemaValidator uses `ex_json_schema` library to validate the given map data with the given schema.
  Schema draft used is http://json-schema.org/draft-04/schema.
  """
  @doc """
  Returns json schema will be used in validation.
  Schema should be compatible with ex_json_schema format.
  """
  @callback json_schema() :: map()

  @doc """
  Returns json schema name. Name should be unique.
  """
  @callback json_schema_name() :: binary()
  defmacro __using__([]) do
    quote do
      alias Staxx.WebApiWeb.JSONSchemaCache

      @doc """
      Validates given data with schema returned from json_schema/0.

      Returns `:ok` if data passes validation.

      Returns `{:error, term()}` if data fails validation.
      """
      @spec validate(map()) :: :ok | {:error, term()}
      def validate(data) do
        schema_name = json_schema_name()

        schema_name
        |> JSONSchemaCache.cached?()
        |> resolve_and_cache(schema_name)
        |> ExJsonSchema.Validator.validate(data)
      end

      @doc """
      Gets schema from cache or from json_schema function depending on first parameter.
      If there is no cached schema it resolves and saves schema in cache.
      Returns schema.
      """
      @spec resolve_and_cache(boolean, any) :: map()
      def resolve_and_cache(true, schema_name), do: JSONSchemaCache.get_schema(schema_name)

      def resolve_and_cache(false, schema_name),
        do:
          json_schema()
          |> ExJsonSchema.Schema.resolve()
          |> JSONSchemaCache.put_schema(schema_name)

      @doc """
      Returns map containing decoded json schema by given file name from the `"static/schema"` schema directory.
      Uses library to decode json defined by `:phoenix` `:json_library` in configs.
      """
      @spec read_from_schema!(binary()) :: map()
      def read_from_schema!(filename) do
        json_lib = Application.get_env(:phoenix, :json_library)

        :code.priv_dir(:web_api)
        |> Path.join("static/schema")
        |> Path.join(filename)
        |> File.read!()
        |> json_lib.decode!()
      end
    end
  end
end
