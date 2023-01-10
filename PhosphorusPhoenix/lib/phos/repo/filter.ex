defmodule Phos.Repo.Filter do
  import Ecto.Query

  defmacrop custom_where(binding, field, val, operator) do
    {operator, [context: Elixir, import: Kernel],
     [
       {:field, [], [binding, {:^, [], [field]}]},
       {:^, [], [val]}
     ]}
  end

  for op <- [:<, :==, :>] do
    def where(query, field_name, unquote(op), value) do
      query
      |> where([o], custom_where(o, field_name, value, unquote(op)))
    end
  end

end
