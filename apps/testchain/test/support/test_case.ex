defmodule Staxx.Testchain.TestCase do
  use ExUnit.CaseTemplate
  alias Staxx.Testchain.Helper
  @moduledoc false
  using do
    quote do
      import Staxx.Testchain.TestCase
      import Staxx.Testchain.Factory
    end
  end

  @doc """
  Cleans DETS snapshots table
  """
  @spec clean_snapshots_table(any) :: :ok
  def clean_snapshots_table(_context) do
    Helper.snapshots_table()
    |> :dets.delete_all_objects()

    :ok
  end

  # Clean snapshots table before each test
  setup :clean_snapshots_table
end
