defmodule Phos.Repo.Migrations.CreateOrbs do
  use Ecto.Migration

  def change do
    create table(:orbs) do
      add :title, :string
      add :active, :boolean, default: false, null: false
      add :media, :boolean, default: false, null: false
      add :extinguish, :naive_datetime

      timestamps()
    end
  end
end
