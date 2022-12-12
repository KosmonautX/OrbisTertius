defmodule Phos.Repo.Migrations.AddParentIdToOrbs do
  use Ecto.Migration

  def change do
    alter table(:orbs) do
      add :path, :ltree
      add :parent_id, references(:orbs, column: :id, type: :uuid)
    end

    create index(:orbs, [:path], using: :gist)
  end
end
