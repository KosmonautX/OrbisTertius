defmodule Phos.Repo.Migrations.AddUniqueIndexOnAuth do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create unique_index(:user_auths, [:auth_id, :auth_provider, :user_id], concurrently: true)
  end
end
