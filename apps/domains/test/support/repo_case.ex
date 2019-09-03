defmodule Staxx.Domains.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Staxx.Domains.Repo

      import Ecto
      import Ecto.Query
      import Staxx.Domains.RepoCase
      import Staxx.Domains.Factory

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Staxx.Domains.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Staxx.Domains.Repo, {:shared, self()})
    end

    :ok
  end
end
