defmodule Phos.Repo.Migrations.AddEmbTables do
  use Ecto.Migration

  def change do
    create table(:orbs_emb) do
      add :title, :string
      add :active, :boolean, default: false, null: false
      add :media, :boolean, default: false, null: false
      add :extinguish, :naive_datetime
      add :payload, {:array, :jsonb}, default: []

      timestamps()
    end

    create table(:orbs_initiator) do
      add :user_id, :string
    end

    create table(:orbs_location) do
      add :hash, :string
      add :hashes, {:array, :string}
      add :radius, :integer
    end
  end
end
