defmodule Staxx.Domains.Repo.Migrations.CreateStackTemplate do
  use Ecto.Migration
  alias Staxx.Domains.Types.StackScope

  def change do
    create table("stack_template") do
      add(:scope, :string, default: StackScope.sandbox)
      add(:name, :string, null: false)
      add(:title, :string)
      add(:icon, :string)
      add(:config, :map, default: %{})
    end
    create(unique_index("stack_template", [:name]))

    create table("stack_template_deps") do
      add(:stack_template_id, references("stack_template", on_delete: :nilify_all))
      add(:stack_template_dep_id, references("stack_template", on_delete: :nilify_all))
    end
    create unique_index("stack_template_deps", [:stack_template_id, :stack_template_dep_id])
  end
end
