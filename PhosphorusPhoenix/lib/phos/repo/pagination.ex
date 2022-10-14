defmodule Phos.Repo.Paginated do
  import Ecto.Query


  def query_builder(query, page, attr, limit) do
    query
    |> order_by(desc: ^attr)
    |> limit(^(limit + 1)) # last element not forwarded to client check downstream exists
    |> offset(^(limit * (page - 1)))
  end

  def all(query, page, attr, limit) when is_binary(page) do
    all(query, String.to_integer(page), attr, limit)
  end


  def all(query, page, attr, limit) when is_integer(page) and is_integer(limit) do
    dao = Phos.Repo.all(query_builder(query, page, attr, limit))
    count = length(dao)

    if(count > limit) do
      %{
      data: dao |> Enum.reverse() |> tl() |> Enum.reverse(), # remove last element
      meta: %{
      pagination: %{
        downstream: true,
        upstream: page > 1,
        current: page,
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
        start: (unless (count==0), do: (page - 1) * limit + 1, else: (page - 1) * limit + count),
        end: (page - 1) * limit + count
     }}}
    end
  end

end
