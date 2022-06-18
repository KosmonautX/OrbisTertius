defmodule Phos.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    alter table(:users) do
      modify :email, :citext, null: false
      add :hashed_password, :string
      remove :password_hash
      add :confirmed_at, :naive_datetime
    end

    create table(:users_tokens) do
      add :user_id, references(:users, column: :id, type: :uuid,  on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
