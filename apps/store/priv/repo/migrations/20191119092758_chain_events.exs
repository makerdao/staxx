defmodule Staxx.Store.Repo.Migrations.ChainEvents do
  use Ecto.Migration

  def change do
    create table("chain_events") do
      add(:chain_id, references("chains", type: :string, on_delete: :delete_all, column: :chain_id), null: false)
      add(:event, :string)
      add(:data, :map)

      timestamps()
    end
    create(index("chain_events", [:chain_id, :event]))
  end
end
