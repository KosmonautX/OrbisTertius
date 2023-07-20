defmodule Phos.Mainland.Postal do

  @world Path.join(:code.priv_dir(:phos), "data/mainland/postal/*.json")
  |> Path.wildcard()
  |> Enum.reduce(%{}, fn path, acc ->
    @external_resource path
    Map.merge(acc, path |> File.read!() |> Jason.decode!() ) end)

  def locate(postal) do
    @world[postal]
  end

  def locate(_), do: nil

end
