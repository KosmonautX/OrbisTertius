defmodule Phos.Repo.Migrations.DropEchoes do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    drop table(:echo), mode: :cascade

    create unique_index(:users, [:fyr_id], name: :unique_fyr, concurrently: true)
  end

 end
