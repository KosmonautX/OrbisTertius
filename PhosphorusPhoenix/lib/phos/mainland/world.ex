defmodule Phos.Mainland.World do

  @world Path.join(:code.priv_dir(:phos), "data/mainland/*.json")
  |> Path.wildcard()
  |> Enum.reduce(%{}, fn path, acc ->
    @external_resource path
    Map.merge(acc, path |> File.read!() |> Jason.decode!() ) end)

  def locate(hash) when is_integer(hash) do
    @world[to_string(:h3.parent(hash, 8))]
  end
  def locate(_), do: nil

  def find_hash(loc) when is_bitstring(loc) do
    Enumerable.reduce(@world, {:cont, nil}, fn {key, val}, _ ->
      String.downcase(loc)
      |> Kernel.==(String.downcase(val))
      |> case do
        true -> {:halt, key}
        _ -> {:cont, nil}
      end
    end)
    |> elem(1)
  end
  def find_hash(_loc), do: nil

end
