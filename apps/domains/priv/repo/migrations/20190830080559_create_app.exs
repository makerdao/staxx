defmodule Staxx.Domains.Repo.Migrations.CreateApp do
  use Ecto.Migration

  def change do
    create table("app") do
      add(:name, :string)
      add(:title, :string)
      add(:icon, :string)
      add(:url, :string)
      add(:deps, {:array, :string}, default: [])
    end
  end
end
