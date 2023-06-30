defmodule Phos.Mainland.Sphere do

  @world Path.join(:code.priv_dir(:phos), "data/mainland/sphere/*.json")
  |> Path.wildcard()
  |> Enum.reduce(%{}, fn path, acc ->
    @external_resource path
    Map.merge(acc, path |> File.read!() |> Jason.decode!() ) end)

  def middle(hash) when is_integer(hash) do
    @world[to_string(:h3.parent(hash, 8))]["mid"]
  end

  def middle(_), do: nil

  def locate(hash) when is_integer(hash) do
    @world[to_string(:h3.parent(hash, 8))]["territory"]
  end

  def locate(_), do: nil

end
