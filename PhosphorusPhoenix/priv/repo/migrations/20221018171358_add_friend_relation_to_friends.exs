defmodule Phos.Repo.Migrations.AddFriendRelationToFriends do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    alter table(:user_relations) do
      add :user_relation_type, :binary
    end

    create index(:user_relations, :user_relation_type, concurrently: true)
  end
end
