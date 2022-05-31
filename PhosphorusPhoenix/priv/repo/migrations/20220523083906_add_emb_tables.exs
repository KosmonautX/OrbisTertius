defmodule Phos.Repo.Migrations.AddEmbTables do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :username, :string
      add :fyr_id, :string
      add :media, :string

      timestamps()
    end

    create index(:users, :username)

    create table(:orbs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :active, :boolean, default: false, null: false
      add :media, :boolean, default: false, null: false
      add :extinguish, :naive_datetime
      add :payload, :jsonb
      add :initiator, references(:users, column: :id, type: :uuid)

      timestamps()
    end

    create table(:locations, primary_key: false) do
      add :id, :bigint, primary_key: true

      timestamps()
    end

    create table(:orbs_location, primary_key: false) do
      add :orb_id, references(:orbs, column: :id, type: :uuid)
      add :location_id, references(:locations, column: :id, type: :bigint)

      timestamps()
    end

    create unique_index(:orbs_location, [:orb_id, :location_id])
  end
end
