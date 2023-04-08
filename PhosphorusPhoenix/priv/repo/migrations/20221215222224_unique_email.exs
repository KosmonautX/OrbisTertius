defmodule Phos.Repo.Migrations.AddUniqueEmails do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create unique_index(:users, [:email], name: :unique_email)
  end
end
