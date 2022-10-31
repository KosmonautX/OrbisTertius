defmodule Phos.Repo.Migrations.CreateIndicesForDeactivation do
  use Ecto.Migration

  def change do

    alter table(:users) do
      add :personalorb_id, references(:orbs, column: :id, type: :uuid)
      remove :profile_pic
    end

    alter table(:orbs) do
      add :userbound, :boolean, default: false
    end

    rename_query = "ALTER TYPE orb_source RENAME VALUE 'flutter' TO 'api'"
    reverse_query = "ALTER TYPE orb_source RENAME VALUE 'flutter' TO 'api'"
    execute(rename_query, reverse_query)

    create index(:orbs, :initiator_id)
    create index(:comments, :initiator_id)
    create index(:comments, :parent_id)

  end
end
