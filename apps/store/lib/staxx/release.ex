defmodule Staxx.Store.Release do
  @app :store

  @doc """
  Runs migrations for Staxx
  """
  @spec migrate() :: term
  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Rolling back migrations for Staxx to given version
  """
  @spec rollback(module, term) :: term
  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
