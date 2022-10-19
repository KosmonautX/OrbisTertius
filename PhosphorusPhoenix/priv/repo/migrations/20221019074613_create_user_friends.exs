defmodule Phos.Repo.Migrations.CreateUserFriends do
  use Ecto.Migration

  def change do
    create table(:user_friends, primary_key: false) do
      add :user_id, references(:users, column: :id, type: :uuid)
      add :friend_id, references(:users, column: :id, type: :uuid)
      add :relation_id, references(:user_relations, column: :id, type: :uuid)
    end

    create index(:user_friends, :user_id)
    create unique_index(:user_friends, [:user_id, :friend_id])
  end
end
