defmodule Phos.Repo.Migrations.AddEmbTables do
  use Ecto.Migration

  def change do
    create table(:orbs, primary_key: false) do
      add :orb_id, :uuid, primary_key: true
      add :title, :string
      add :active, :boolean, default: false, null: false
      add :media, :boolean, default: false, null: false
      add :extinguish, :naive_datetime
      add :payload, :jsonb

      timestamps()
    end

    create table(:locations, primary_key: false) do
      add :location_id, :bigint, primary_key: true

      timestamps()
    end

    create table(:orbs_location, primary_key: false) do
      add :orb_id, references(:orbs, column: :orb_id, type: :uuid)
      add :location_id, references(:locations, column: :location_id, type: :bigint)

      timestamps()
    end

    create unique_index(:orbs_location, [:orb_id, :location_id])
  end
end
