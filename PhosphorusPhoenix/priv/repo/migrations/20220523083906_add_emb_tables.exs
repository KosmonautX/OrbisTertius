defmodule Phos.Repo.Migrations.AddEmbTables do
  use Ecto.Migration

  def change do
    create table(:tele, primary_key: false) do
      add :id, :string, primary_key: true

      # timestamps()
    end

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :username, :string
      add :media, :boolean, default: false, null: false
      add :profile_pic, :integer
      add :fyr_id, :string

      timestamps()
    end

    create unique_index(:users, [:username], name: :unique_username)


    create table(:public_profile, primary_key: false) do
      add :user_id, :uuid, primary_key: true
      add :birthday, :naive_datetime
      add :bio, :string

      timestamps()
    end

    create table(:private_profile, primary_key: false) do
      add :user_id, :uuid, primary_key: true
      add :geohash, :jsonb

      timestamps()
    end

    create table(:orbs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :active, :boolean, default: false, null: false
      add :media, :boolean, default: false, null: false
      add :extinguish, :naive_datetime
      add :payload, :jsonb
      add :orb_nature, :string
      add :initiator, references(:users, column: :id, type: :uuid)
      add :traits, :jsonb

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
    create unique_index(:orbs_location, [:location_id, :orb_id], name: :same_orb_within_location)
  end

end
