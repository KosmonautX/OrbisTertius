defmodule Phos.Repo.Migrations.AddEmbTables do
  use Ecto.Migration

  def change do
    create table(:orbs_emb, primary_key: false) do
      add :orb_id, :uuid, primary_key: true
      add :title, :string
      add :active, :boolean, default: false, null: false
      add :media, :boolean, default: false, null: false
      add :extinguish, :naive_datetime
      add :payload, :jsonb

      timestamps()
    end

    create table(:orbs_location, primary_key: false) do
      add :location_id, :string, primary_key: true

      timestamps()
    end

    create table(:orbs_orb_location, primary_key: false) do
      add :orb_id, references(:orbs_emb, column: :orb_id, type: :uuid)
      add :location_id, references(:orbs_location, column: :location_id, type: :string)

      timestamps()
    end

    create table(:orbs_initiator) do
      add :user_id, :string

      timestamps()
    end
  end
end
