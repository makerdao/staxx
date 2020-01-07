defmodule Staxx.Store.Repo.Migrations.Chain do
  use Ecto.Migration

  def change do
    create table("chains", primary_key: false) do
      add(:uuid, :uuid, primary_key: true)
      add(:user_id, references("users", on_delete: :delete_all), null: true)
      add(:chain_id, :string)
      add(:title, :string)
      add(:node_type, :string)
      add(:status, :string, default: "initializing")
      add(:config, :map)
      add(:details, :map)
      add(:deployment, :map)

      timestamps()
    end
    create(unique_index("chains", [:chain_id]))
    create(index("chains", [:node_type]))
  end
end
