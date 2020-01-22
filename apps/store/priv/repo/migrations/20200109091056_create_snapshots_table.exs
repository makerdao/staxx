defmodule Staxx.Store.Repo.Migrations.CreateSnapshotsTable do
  use Ecto.Migration

  def change do
    create table("snapshots", primary_key: false) do
      add(:id, :string, primary_key: true, autogenerate: false)
      add(:description, :string)
      add(:path, :string)
      add(:chain, :string)

      timestamps()
    end
    create unique_index("snapshots", [:id])
  end
end
