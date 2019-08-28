defmodule Staxx.Domains.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table("users") do
      add(:email, :string)
      add(:admin, :boolean, default: false)
      add(:active, :boolean, default: true)
      add(:name, :string)
      add(:preferences, :map, default: %{}1)
    end

    create(unique_index("users", [:email]))
    create(index("users", [:email]))
  end
end
