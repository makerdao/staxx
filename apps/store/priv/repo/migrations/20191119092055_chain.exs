defmodule Staxx.Store.Repo.Migrations.Chain do
  use Ecto.Migration

  def change do
    create table("chains", primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:user_id, references("users", on_delete: :delete_all), null: true)
      add(:title, :string)
      add(:node_type, :string)
      add(:status, :string, default: "initializing")
      add(:config, :map)
      add(:details, :map)
      add(:deployment, :map)

      timestamps()
    end
    create(unique_index("chains", [:id]))
    create(index("chains", [:node_type]))
  end
end
