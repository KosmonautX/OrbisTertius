defmodule Phos.Repo.Migrations.CreateOrbCollaborators do
  use Ecto.Migration

  def change do
    create table(:orb_permissions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :orb_id, references(:orbs, on_delete: :nothing, column: :id, type: :uuid)
      add :member_id, references(:users, on_delete: :nothing, column: :id, type: :uuid)
      add :token_id, references(:users_tokens, on_delete: :nothing, column: :id)
      add :action, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:orb_permissions, [:orb_id])
    create unique_index(:orb_permissions, [:orb_id, :member_id])
  end
end
