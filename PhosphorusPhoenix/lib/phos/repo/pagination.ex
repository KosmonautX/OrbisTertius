defmodule Phos.Repo.Paginated do
  import Ecto.Query

  def query_builder(query, page, limit, attr) when is_integer(page) and is_integer(limit) do
    query
    |> order_by(desc: ^attr)
    |> limit(^(limit + 1)) # last result not forwarded to client check last page
    |> offset(^(limit * (page - 1)))
  end

  def all(query, page, limit \\ 12, attr \\ :inserted_at) when is_integer(page) and is_integer(limit) do

    dao = Phos.Repo.all(query_builder(query, page, limit, attr))
    count = length(dao)

    %{
      data: dao |> List.pop_at(-1),
      meta: %{
      pagination: %{
        downstream: count > limit,
        upstream: page > 1,
        current: page,
        start: (page - 1) * limit + 1 ,
        end: (page - 1) * limit + count
     }}}
  end

end
