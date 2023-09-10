defmodule Phos.Repo.Migrations.CreateVectorExtension do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    alter table(:orbs) do
      add :embedding, :vector, size: 384
    end

    execute("CREATE INDEX ON orbs USING hnsw(embedding vector_l2_ops) WITH (m=16, ef_construction=64)")
  end

  def down do
    alter table(:orbs) do
      remove_if_exists :embedding, :vector
    end

    drop_if_exists index(:orbs, ["embedding vector_l2_ops"], mode: :cascade)
    execute("DROP EXTENSION IF EXISTS vector")
  end
end
