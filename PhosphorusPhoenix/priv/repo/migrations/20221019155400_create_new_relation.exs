defmodule Phos.Repo.Migrations.CreateNewRelation do
  use Ecto.Migration

  def up do
    drop_if_exists table(:user_friends), mode: :cascade
    drop_if_exists table(:user_relations), mode: :cascade

    create table(:user_relations, primary_key: false) do
      add :user_id, references(:users, column: :id, type: :uuid)
      add :friend_id, references(:users, column: :id, type: :uuid)
      add :completed_at, :naive_datetime
      add :information_id, references(:user_relation_informations, column: :id, type: :uuid)
    end
  end

  def down do
    drop_if_exists table(:user_relations)

    create table(:user_relations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :requester_id, references(:users, column: :id, type: :uuid)
      add :acceptor_id, references(:users, column: :id, type: :uuid)
      add :requested_at, :naive_datetime, default: fragment("now()")
      add :accepted_at, :naive_datetime, null: true
      add :state, :string, default: "requested"
      add :user_relation_type, :binary
    end

    create table(:user_friends, primary_key: false) do
      add :user_id, references(:users, column: :id, type: :uuid)
      add :friend_id, references(:users, column: :id, type: :uuid)
      add :relation_id, references(:user_relations, column: :id, type: :uuid)
    end

    create index(:user_relations, :requested_at)
    create index(:user_relations, :accepted_at)
    create index(:user_relations, :state)
    create index(:user_relations, :user_relation_type)
    create index(:user_friends, :user_id)
    create unique_index(:user_friends, [:user_id, :friend_id])
  end
end
