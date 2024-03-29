defmodule Phos.Repo.Migrations.EchoMigration do
  use Ecto.Migration

  ## Ecto.Migrator.with_repo(Phos.Repo, &Ecto.Migrator.run(&1, :down, to: 20221215222222))

  def change do
    create table(:memories, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_source_id, references(:users, on_delete: :nothing, column: :id, type: :uuid)
      add :orb_subject_id, references(:orbs, on_delete: :nothing, column: :id, type: :uuid)
      add :rel_subject_id, references(:user_relations_root, on_delete: :nothing, column: :id, type: :uuid)
      add :com_subject_id, references(:comments, on_delete: :nothing, column: :id, type: :uuid)
      add :action_path, :string
      add :message, :string
      add :media, :boolean, default: false, null: false
      timestamps([type: :utc_datetime_usec])
    end

    create index(:memories, [:orb_subject_id])
    create index(:memories, [:rel_subject_id])


    create table(:reveries, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :read, :utc_datetime
      add :memory_id, references(:memories, on_delete: :delete_all, column: :id, type: :uuid)
      add :user_destination_id, references(:users, on_delete: :delete_all, column: :id, type: :uuid)
      timestamps([type: :utc_datetime_usec])
    end

    create index(:reveries, [:user_destination_id])
    create index(:reveries, [:memory_id])

  end
end
