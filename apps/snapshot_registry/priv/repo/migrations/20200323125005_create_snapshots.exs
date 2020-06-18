defmodule Staxx.SnapshotRegistry.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table("snapshots", primary_key: false) do
      add(:id, :string, primary_key: true, autogenerate: false)
      add(:description, :string)
      add(:chain_type, :string)

      timestamps()
    end

    create unique_index("snapshots", [:id])
  end
end
