defmodule Phos.Repo.Migrations.AddLocSubjectMemory do
  use Ecto.Migration

  def change do
    alter table(:memories) do
      add :loc_subject_id, references(:locations, column: :id, type: :bigint)
    end

    alter table(:locations) do
      add :last_memory_id, references(:memories, on_delete: :nothing, column: :id, type: :uuid)
    end

    create index(:memories, [:loc_subject_id])
  end
end
