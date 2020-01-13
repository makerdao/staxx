defmodule Staxx.Store.Repo.Migrations.Users do
  use Ecto.Migration

  def change do
    create table("users") do
      add(:email, :string)
      add(:admin, :boolean, default: false)
      add(:active, :boolean, default: true)
      add(:name, :string)
      add(:preferences, :map, default: %{})

      timestamps()
    end
    create(unique_index("users", [:email]))
  end
end
