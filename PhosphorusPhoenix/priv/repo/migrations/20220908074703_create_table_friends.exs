defmodule Phos.Repo.Migrations.CreateTableFriends do
  use Ecto.Migration

  def change do
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
