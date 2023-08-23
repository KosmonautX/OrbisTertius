defmodule Phos.Repo.Migrations.CreateVectorExtension do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    alter table(:orbs) do
      add :embedding, :vector, size: 768
    end

    create index(:orbs, ["embedding vector_cosine_ops"], using: :ivfflat)
  end

  def down do
    alter table(:orbs) do
      remove_if_exists :embedding, :vector
    end

    drop_if_exists index(:orbs, ["embedding vector_cosine_ops"], mode: :cascade)
    execute("DROP EXTENSION IF EXISTS vector")
  end
end
