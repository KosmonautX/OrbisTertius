defmodule Phos.Repo.Migrations.AddRelationshipLastMemory do
  use Ecto.Migration

  def change do

    alter table(:user_relations_root) do
      add :last_memory_id, references(:memories, on_delete: :nothing, column: :id, type: :uuid)
    end

  end
end
