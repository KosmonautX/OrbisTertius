 defmodule Phos.Repo.Paginated do
  import Ecto.Query

  def query_builder(query, opts) do
    sort_attribute = Keyword.get(opts, :sort_attribute, :inserted_at)
    limit = Keyword.get(opts, :limit, 12)
    ascending? = Keyword.get(opts, :asc, false)
    filter = Keyword.get(opts, :filter, nil)

    query
    |> maybe_ascend(sort_attribute, ascending?)
    |> limit(^(limit + 1)) # last element not forwarded to client check downstream exists
    |> maybe_filter(sort_attribute, ascending?, filter)
  end

  defp maybe_ascend(query, attr, false), do: query |> order_by(desc: ^attr)
  defp maybe_ascend(query, attr, true), do: query |> order_by(asc: ^attr)

  defp maybe_filter(query, _attr, _ascending, nil), do: query
  defp maybe_filter(query, attr, false, filter), do: query |> Phos.Repo.Filter.where(attr, :<, filter)
  defp maybe_filter(query, attr, true, filter), do: query |> Phos.Repo.Filter.where(attr, :>, filter)

  def query_builder(query, page, attr, limit) do
    query
    |> order_by(desc: ^attr)
    |> limit(^(limit + 1)) # last element not forwarded to client check downstream exists
    |> offset(^(limit * (page - 1)))
  end


  def all(query, opts) when is_list(opts) do

    limit = Keyword.get(opts, :limit, 12)
    ascending? = Keyword.get(opts, :asc, false)
    sort = Keyword.get(opts, :sort_attribute, :inserted_at)

    dao = query
    |> query_builder(opts)
    |> Phos.Repo.all()

    count = length(dao)

    if(count > limit) do
      [ _ | [head| _] = resp ] = dao |> Enum.reverse()
      %{
      data: resp |> Enum.reverse(), # remove last element
      meta: %{
      pagination: %{
        downstream: true,
        count: limit,
        cursor: Map.get(head, sort) |> DateTime.to_unix(:millisecond)
     }}}
    else
      %{
      data: dao,
      meta: %{
        pagination: %{
        count: length(dao),
        downstream: false
     }}}
    end
  end

  def all(query, page, attr, limit) when is_binary(page) do
    all(query, String.to_integer(page), attr, limit)
  end


  def all(query, page, attr, limit) when is_integer(page) and is_integer(limit) do
    dao = Phos.Repo.all(query_builder(query, page, attr, limit))
    total = Phos.Repo.aggregate(query, :count, attr)
    count = length(dao)

    if(count > limit) do
      %{
      data: dao |> Enum.reverse() |> tl() |> Enum.reverse(), # remove last element
      meta: %{
      pagination: %{
        downstream: true,
        upstream: page > 1,
        current: page,
        total: total,
        start: (page - 1) * limit + 1 ,
        end: (page - 1) * limit + limit
     }}}
    else
      %{
      data: dao, # remove last element
      meta: %{
      pagination: %{
        downstream: false,
        upstream: page > 1,
        current: page,
        total: total,
        start: (unless (count==0), do: (page - 1) * limit + 1, else: (page - 1) * limit + count),
        end: (page - 1) * limit + count
     }}}
    end
  end

end
