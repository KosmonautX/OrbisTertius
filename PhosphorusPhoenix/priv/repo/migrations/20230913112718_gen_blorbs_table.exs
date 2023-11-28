defmodule Phos.Repo.Migrations.GenBlorbsTable do
  use Ecto.Migration

  def change do
    create table(:blorbs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string
      add :active, :boolean, default: true, null: true
      add :character, :jsonb
      add :initiator_id, references(:users, column: :id, type: :uuid)
      add :orb_id, references(:orbs, column: :id, type: :uuid, on_delete: :delete_all)

      timestamps()
    end

    create index(:blorbs, :orb_id)
  end
end
