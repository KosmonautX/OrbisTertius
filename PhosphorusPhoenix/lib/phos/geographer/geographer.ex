defmodule Phos.Geographer do
  alias Phos.Action
  alias PhosWeb.Menshen.Auth

  def parse_territories(socket, map_param) do
    map = Enum.map(map_param, fn {k, v} ->
      if Auth.check_territory?(socket, v) do
        IO.puts("authorized")
        %{k => v["hash"] |> to_charlist() |> :h3.from_string() |> Action.get_orbs_by_geohash()}
      else
        IO.puts("not authorized")
      end
    end)

    IO.inspect map
  end
end

    # SUTD inside target 10
    # target_territory = %{"work" => %{"hash" => "8a6526ac3427fff", "radius" => 10}}

    # target_territory = %{"work" => %{"hash" => "8a6526ac3427fff", "radius" => 10}, "live" => %{"hash" => "886526ac35fffff", "radius" => 10}}
