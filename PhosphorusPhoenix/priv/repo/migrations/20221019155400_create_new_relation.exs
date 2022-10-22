defmodule Phos.Repo.Migrations.CreateNewRelation do
  use Ecto.Migration

  def up do
    drop_if_exists table(:user_friends), mode: :cascade
    drop_if_exists table(:user_relations), mode: :cascade

    create table(:user_relations_branches, primary_key: false) do
      add :user_id, references(:users, column: :id, type: :uuid), primary_key: true
      add :friend_id, references(:users, column: :id, type: :uuid), primary_key: true
      add :completed_at, :naive_datetime
      add :root_id, references(:user_relations_root, column: :id, type: :uuid)
    end

    create unique_index(:user_relations_branches, [:user_id, :friend_id], name: :mutual_relation_index)

  end

  def down do
    drop_if_exists table(:user_relations_branches)

    create table(:user_relations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :requester_id, references(:users, column: :id, type: :uuid)
      add :acceptor_id, references(:users, column: :id, type: :uuid)
      add :requested_at, :naive_datetime, default: fragment("now()")
      add :accepted_at, :naive_datetime, null: true
      add :state, :string, default: "requested"
    end

    create index(:user_relations, :requested_at)
    create index(:user_relations, :accepted_at)
    create index(:user_relations, :state)
  end
end
