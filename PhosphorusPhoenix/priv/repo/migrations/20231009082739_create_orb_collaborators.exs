defmodule Phos.Repo.Migrations.CreateOrbCollaborators do
  use Ecto.Migration

  def change do
    create table(:orb_permissions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :orb, references(:orbs, on_delete: :nothing, column: :id, type: :uuid)
      add :user, references(:users, on_delete: :nothing, column: :id, type: :uuid)
      add :state, :integer

      timestamps(type: :utc_datetime_usec)
    end
  end
end
