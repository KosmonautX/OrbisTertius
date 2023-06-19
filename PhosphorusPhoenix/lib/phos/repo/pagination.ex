defmodule Phos.Repo.Paginated do
  import Ecto.Query

  def query_builder(query, opts \\ [])
  def query_builder(query, opts) do
    sort_attribute = Keyword.get(opts, :sort_attribute, :inserted_at)
    limit = Keyword.get(opts, :limit, 12)
    ascending? = Keyword.get(opts, :asc, false)
    filter = Keyword.get(opts, :filter, nil)
    page = Keyword.get(opts, :page, nil)

    query
    |> maybe_ascend(sort_attribute, ascending?)
    |> limit(^(limit + 1)) # last element not forwarded to client check downstream exists
    |> maybe_filter(sort_attribute, ascending?, filter)
    |> maybe_page(limit, page)
  end

  def query_builder(query, page, attr, limit), do: query_builder(query, [sort_attribute: attr, limit: limit, page: page])

  #named binding
  defp maybe_ascend(query, {as, field}, false), do: from [{^as, x}] in query, order_by: [{:desc, field(x, ^field)}]
  defp maybe_ascend(query, {as, field}, true), do: from [{^as, x}] in query, order_by: [{:asc, field(x, ^field)}]
  defp maybe_ascend(query, attr, false), do: query |> order_by(desc: ^attr)
  defp maybe_ascend(query, attr, true), do: query |> order_by(asc: ^attr)
  defp maybe_ascend(query, _attr, nil), do: query

  defp maybe_filter(query, _attr, _ascending, nil), do: query
  defp maybe_filter(query, attr, false, filter), do: query |> Phos.Repo.Filter.where(attr, :<, filter)
  defp maybe_filter(query, attr, true, filter), do: query |> Phos.Repo.Filter.where(attr, :>, filter)

  defp maybe_page(query, _limit, nil), do: query
  defp maybe_page(query, limit, page) when is_binary(page), do: maybe_page(query, limit, String.to_integer(page))
  defp maybe_page(query, limit, page), do: query |> offset(^(limit * (page - 1)))


  def all(query, opts) when is_list(opts) do
    limit = Keyword.get(opts, :limit, 12)
    sort = case Keyword.get(opts, :sort_attribute, :inserted_at) do
             {_key, sort_attr} -> sort_attr
             sort_attr -> sort_attr
           end

    dao = query
    |> query_builder(opts)
    |> Phos.Repo.all()

    count = length(dao)

    case Keyword.fetch(opts, :page) do
      # page-based
      {:ok, page} ->
        if Keyword.get(opts, :aggregate, true) do
          total =  Phos.Repo.aggregate(query, :count, sort)
          page_response(dao, page, total, limit)
        else
          page_response(dao, page, nil, limit)
        end

      :error ->
      cond do
        count > limit ->
          [ _ | [head| _] = resp ] = dao |> Enum.reverse()
          %{data: resp |> Enum.reverse(), # remove last element
            meta: %{
              pagination: %{
                downstream: true,
                count: limit,
                cursor: Map.get(head, sort) |> DateTime.from_naive!("UTC") |> DateTime.to_unix(:second)}}}

          count != 0 ->
            [head | _ ] = dao |> Enum.reverse()
            %{data: dao,
              meta: %{
                pagination: %{
                  count: count,
                  downstream: false,
                  cursor: Map.get(head, sort) |> DateTime.from_naive!("UTC")  |> DateTime.to_unix(:second)}}}

          count == 0 ->
            %{data: [],
              meta: %{
                pagination: %{
                  count: 0,
                  downstream: false
                  #cursor: Keyword.get(opts, :filter, nil) |> DateTime.from_naive!("UTC")  |> DateTime.to_unix(:second)
                }}}
        end
     end
  end

  def all(query, page, attr, limit), do: all(query, [sort_attribute: attr, limit: limit, page: page])

  def page_response(dao, page, total, limit) when is_binary(page), do: page_response(dao, String.to_integer(page), total, limit)
  def page_response(dao, page, total, limit) when is_binary(limit), do: page_response(dao, page, total, String.to_integer(limit))
  def page_response(dao, page, total, limit) do
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
                count: count,
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
                count: count,
                total: total,
                start: (unless (count==0), do: (page - 1) * limit + 1, else: (page - 1) * limit + count),
                end: (page - 1) * limit + count
              }}}
        end
   end
end
