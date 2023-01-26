defmodule Phos.Mainland.World do

  @world Path.join(:code.priv_dir(:phos), "data/mainland/*.json")
  |> Path.wildcard()
  |> Enum.reduce(%{}, fn path, acc ->
    @external_resource path
    Map.merge(acc, path |> File.read!() |> Jason.decode!() ) end)

  def locate(hash) when is_integer(hash) do
    @world[to_string(hash)]
  end

  def locate(_), do: nil

end
