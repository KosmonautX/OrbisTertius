defmodule Phos.Repo.Migrations.AddCommentsTable do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION ltree", "DROP EXTENSION ltree")

    create table(:comments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :active, :boolean, default: false
      add :body, :text, null: false
      add :path, :ltree
      add :orb_id, references(:orbs, column: :id, type: :uuid)
      add :initiator_id, references(:users, column: :id, type: :uuid)
      add :parent_id, references(:comments, column: :id, type: :uuid)

      timestamps()
    end

    create index(:comments, [:path])
    create index(:comments, [:orb_id])
  end
end
