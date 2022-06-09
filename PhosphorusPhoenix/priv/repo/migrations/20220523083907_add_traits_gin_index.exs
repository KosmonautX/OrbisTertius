defmodule Phos.Repo.Migrations.Add_Traits_GIN do
  use Ecto.Migration
  # https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING
  def up do
    execute("CREATE INDEX orbs_traits_index ON orbs USING GIN(traits jsonb_path_ops)")
  end

  def down do
    execute("DROP INDEX orbs_traits_index")
  end
end
