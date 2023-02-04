defmodule Phos.Utility.Geo do

  def top_occuring(list, places) when is_list(list) do
    list
    |> Enum.map(fn t -> Phos.Mainland.World.locate(t) end)
        |> List.foldl(%{}, fn
      nil, acc -> acc
      t, acc -> Map.update(acc, t, 1, fn c -> c + 1 end)
      end)
        |> Enum.map(fn {k,v} -> {k,v} end)
        |> List.keysort(1, :desc)
        |> Enum.take(places)
        |> Enum.map(fn t -> elem(t, 0) end)
  end

end
