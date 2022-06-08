defmodule PhosWeb.Util.Geographer do
  alias Phos.Action
  alias PhosWeb.Menshen.Auth
  alias PhosWeb.Util.Viewer

  @moduledoc """
  For all our Geography centered Util Functions
  """

  def parse_territories(socket, map_param) do
    Enum.map(map_param, fn {k, v} ->
      if Auth.check_territory?(socket, v) do
        {:ok, %{k => v["hash"] |> to_charlist() |> :h3.from_string() |> Action.get_orbs_by_geohash() |> Viewer.orb_mapper()}}
      else
        {:error, "unauthorized"}
      end
    end)
  end
end
