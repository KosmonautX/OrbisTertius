defmodule Phos.Geographer do
  alias Phos.Action
  alias PhosWeb.Menshen.Auth

  def parse_territories(socket, map_param) do
    Enum.map(map_param, fn {k, v} ->
      if Auth.check_territory?(socket, v) do
        {:ok, %{k => v["hash"] |> to_charlist() |> :h3.from_string() |> Action.get_orbs_by_geohash() |> orb_mapper()}}
      else
        {:error, "unauthorized"}
      end
    end)
  end

  defp orb_mapper(orbs) do
    Enum.map(orbs, fn orb ->
      %{
        title: orb.location_id,
        info: orb.orbs.payload.info,
        when: orb.orbs.payload.when,
        tip: orb.orbs.payload.tip
      }
    end)
  end
end
