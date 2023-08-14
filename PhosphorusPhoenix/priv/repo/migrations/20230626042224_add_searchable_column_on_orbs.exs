defmodule Phos.Repo.Migrations.AddSearchableColumnOnOrbs do
  use Ecto.Migration

  def up do
    execute("""
      CREATE INDEX orbs_traits_vector_index ON orbs
        USING gist((to_tsvector('english', traits::text)));
      """)

    execute("""
      CREATE INDEX orbs_title_vector_index ON orbs
        USING gist((to_tsvector('english', title)));
    """)
  end

  def down do
    execute("DROP INDEX orbs_traits_vector_index")
    execute("DROP INDEX orbs_title_vector_index")
  end
end
