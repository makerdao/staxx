defmodule Staxx.Testchain.TestCase do
  use ExUnit.CaseTemplate
  @moduledoc false
  using do
    quote do
      import Staxx.Testchain.TestCase
      import Staxx.Testchain.Factory
    end
  end

  @table "snapshots"

  def clean_snapshots_table(_context) do
    :storage
    |> Application.get_env(:dets_db_path)
    |> Path.expand()
    |> Path.join(@table)
    |> String.to_atom()
    |> :dets.delete_all_objects()

    :ok
  end

  setup :clean_snapshots_table
end
