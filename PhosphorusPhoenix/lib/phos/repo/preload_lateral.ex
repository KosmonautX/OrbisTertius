defmodule Phos.Repo.Preloader do
  alias Phos.Repo
  import Ecto.Query

  @doc """
  Preloads *n* items per entity for the given association, similar to an `INNER JOIN LATERAL`,
  but using window functions.
      orb_list
      |> Repo.preload(:initiator)
      |> Repo.Preloader.lateral(:comments, limit: 5, assocs: [:initiator])
  ## Options
    - `:limit` (default: `2`) How many items to preload
    - `:order_by` A `{direction, field}` tuple to order the results
    - `:assocs` What to preload after items have been retrieved. It is directly passed to `Repo.preload`.
  """

  def lateral(entities, assoc, opts \\ [])
  def lateral([], _, _), do: []
  def lateral(nil, _, _), do: nil
  def lateral([%source_queryable{} | _] = entities, assoc, opts) do
    limit = Keyword.get(opts, :limit, 2)
    where = Keyword.get(opts, :where, true)
    {order_direction, order_field} = Keyword.get(opts, :order_by, {:desc, :inserted_at})

    _fields = source_queryable.__schema__(:fields)

    %{
      related_key: related_key,
      queryable: assoc_queryable
    } = source_queryable.__schema__(:association, assoc)

    ids = Enum.map(entities, fn entity -> entity.id end)

    where = dynamic([p], field(p, ^related_key) in ^ids and ^where)

    sub = from(
      p in assoc_queryable,
      where: ^where,
      # select: map(p, ^fields),
      select_merge: %{
        _n: row_number() |> over(
          partition_by: field(p, ^related_key),
          order_by: [{^order_direction, field(p, ^order_field)}]
        )
      }
    )

    query =
      from(
        p in subquery(sub),
        where: p._n <= ^limit,
        select: p)

    preload_assocs = Keyword.get(opts, :assocs)

    ## Repo.Paginated.all() merge through Time
    results =
     Repo.all(query)
      |> results_to_struct(assoc_queryable)
      |> maybe_preload_assocs(preload_assocs)
      |> Enum.group_by(fn entity -> Map.get(entity, related_key) end)

    add_results_to_entities(entities, assoc, results)
  end

  def lateral(%_source_queryable{} = entity, assoc, opts) do
    [preloaded_entity] = lateral([entity], assoc, opts)
    preloaded_entity
  end

  defp results_to_struct(entities, s) do
    Enum.map(entities, fn x -> struct(s,x |> Map.delete(:__struct__)) end)
  end

  defp maybe_preload_assocs(entities, nil), do: entities
  defp maybe_preload_assocs(entities, assocs) do
    Phos.Repo.preload(entities, assocs)
  end

  defp add_results_to_entities(entities, assoc, results) do
    Enum.map(entities, fn entity -> Map.put(entity, assoc, Map.get(results, entity.id, [])) end)
  end

end
