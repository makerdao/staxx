defmodule Staxx.SnapshotRegistry.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Staxx.SnapshotRegistry.Repo

      import Ecto
      import Ecto.Query
      import Staxx.SnapshotRegistry.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Staxx.SnapshotRegistry.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Staxx.SnapshotRegistry.Repo, {:shared, self()})
    end

    :ok
  end
end
