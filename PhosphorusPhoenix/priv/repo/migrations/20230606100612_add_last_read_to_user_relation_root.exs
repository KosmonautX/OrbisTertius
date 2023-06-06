defmodule Phos.Repo.Migrations.AddLastReadToUserRelationRoot do
  use Ecto.Migration

  def change do
    alter table(:user_relations_root) do
      add :last_read_at, :naive_datetime, null: true
    end
  end
end
