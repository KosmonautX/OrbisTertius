defmodule Phos.Repo.Migrations.AddLocSubjectMemory do
  use Ecto.Migration

  def change do
    alter table(:memories) do
      add :loc_subject_id, references(:locations, column: :id, type: :bigint)
    end

    create index(:memories, [:loc_subject_id])
  end
end
