defmodule Stacks do
  @moduledoc """
  Set of function for managing stacks
  """
  alias Stacks.ConfigLoader

  @doc """
  Validate if all stacks are allowed to start
  """
  @spec validate([binary]) :: :ok | {:error, term}
  def validate([]), do: :ok

  def validate(list) do
    result =
      list
      |> Enum.reject(&(&1 == "testchain"))
      |> Enum.filter(fn stack_name -> ConfigLoader.get(stack_name) == nil end)

    case result do
      [] ->
        :ok

      list ->
        {:error, "Not all stacks are allowed to be started ! #{inspect(list)}"}
    end
  end

  @doc """
  Get list of stack names that need to be started
  """
  @spec get_stack_names(map) :: [binary]
  def get_stack_names(params) when is_map(params) do
    params
    |> Map.keys()
    |> Enum.reject(&(&1 == "testchain"))
  end
end
