defmodule Phos.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    alter table(:users) do
      add :role, :string, null: true
    end

    create index(:users, :role, concurrently: true)
  end
end
