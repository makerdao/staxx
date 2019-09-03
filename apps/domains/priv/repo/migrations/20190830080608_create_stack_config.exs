defmodule Staxx.Domains.Repo.Migrations.CreateStackConfig do
  use Ecto.Migration

  def change do
    create table("stack_config") do
      add(:template, references("stack_template"))
      add(:config, :map, default: %{})
    end
  end
end
