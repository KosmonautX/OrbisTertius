defmodule Phos.Repo.Migrations.AddMemoryReply do
  use Ecto.Migration

  def change do
    alter table(:memories) do
      add :mem_subject_id, references(:memories, on_delete: :nilify_all, column: :id, type: :uuid)
    end
  end
end
