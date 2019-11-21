defmodule Staxx.Store.Repo.Migrations.ChainEvents do
  use Ecto.Migration

  def change do
    create table("chain_events", primary_key: false) do
      add(:uuid, :uuid, primary_key: true)
      add(:chain_uuid, references("chains", type: :uuid, on_delete: :delete_all, column: :uuid), null: false)
      add(:event, :string)
      add(:data, :map)

      timestamps()
    end
    create(index("chain_events", [:chain_uuid, :event]))
  end
end
