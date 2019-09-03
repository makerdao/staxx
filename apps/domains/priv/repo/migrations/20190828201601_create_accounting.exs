defmodule Staxx.Domains.Repo.Migrations.CreateAccounting do
  use Ecto.Migration

  def change do
    create table("qa_manager") do
      add(:name, :string)
      add(:domain, :string)
    end

    create table("organization") do
      add(:qa_manager_id, references("qa_manager", on_delete: :delete_all))
      add(:name, :string)
      add(:domain, :string)
      add(:admin, :boolean, default: false)
      add(:active, :boolean, default: true)
    end

    create table("users") do
      add(:organization_id, references("organization", on_delete: :delete_all))
      add(:email, :string)
      add(:admin, :boolean, default: false)
      add(:active, :boolean, default: true)
      add(:name, :string)
      add(:preferences, :map, default: %{})
    end
    create(unique_index("users", [:email]))

    create table("sandbox") do
      add(:name, :string)
    end
  end
end
