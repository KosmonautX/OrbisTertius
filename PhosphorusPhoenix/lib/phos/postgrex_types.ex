Postgrex.Types.define(
  Phos.PostgresTypes,
  [EctoLtree.Postgrex.Lquery, EctoLtree.Postgrex.Ltree, Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions()
)
