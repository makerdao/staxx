defmodule Staxx.Domains.Repo.Migrations.CreateStackCatalog do
  use Ecto.Migration

  def change do
    create table("stack_catalog") do
      add(:name, :string)
    end
  end
end
