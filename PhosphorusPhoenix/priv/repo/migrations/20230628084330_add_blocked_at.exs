defmodule Phos.Repo.Migrations.AddBlockedAt do
  use Ecto.Migration

  def change do
    alter table(:user_relations_branches) do
      add :blocked_at, :naive_datetime, null: true
    end
  end
end
