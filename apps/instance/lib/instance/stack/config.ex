defmodule Staxx.Instance.Stack.Config do
  @moduledoc """
  Default stack configuration structure.
  Stack configuration should be stored into `stack_name/stack.json` file.
  """

  @type t :: %__MODULE__{
          name: binary,
          title: binary,
          scope: binary,
          manager: binary | nil,
          deps: [binary],
          containers: map
        }

  # @enforce_keys [:name]
  defstruct name: "",
            title: "",
            scope: "user",
            manager: nil,
            deps: [],
            containers: %{}

  @doc """
  Checks if given docker image exists in stack configuration.
  """
  @spec has_image?(t(), binary) :: boolean
  def has_image?(%__MODULE__{containers: containers, manager: manager}, image) do
    case image == manager do
      true ->
        true

      false ->
        containers
        |> Enum.map(fn {_name, details} -> Map.get(details, :image) end)
        |> Enum.reject(&is_nil/1)
        |> Enum.member?(image)
    end
  end

  def has_image?(_, _), do: false
end
