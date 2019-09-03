defmodule Staxx.Domains.Repo.Migrations.CreateDeploymentScope do
  use Ecto.Migration

  def change do
    create table("deployment_scope") do
      add(:user_id, references("users"))
      add(:title, :string)
      add(:state, :string, null: true)
    end
  end
end
