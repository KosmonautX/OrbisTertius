defmodule PhosWeb.Util.Geographer do
  alias PhosWeb.Menshen.Auth

  @moduledoc """
  For all our Geography centered Util Functions
  """

  # def parse_territories(socket, target_territories) do
  #   Enum.map(target_territories, fn {k, v} ->
  #     if check_territory?(socket, v) do
  #       # {:ok, %{k => v["hash"] |> to_charlist() |> :h3.from_string() |> Action.get_orbs_by_geohashes() |> Viewer.orb_mapper()}}
  #       {:ok, "#{k} authorized"}
  #     else
  #       {:error, %{reason: "unauthorized"}}
  #     end
  #   end)
  # end

  # Returns true if target territory's parent = socket's claim territory
  def check_territory?(%{assigns: assigns} = _socket, target_territory) do
    case Auth.validate_user(assigns.session_token) do
      {:ok , claims} -> check_territory_validity(target_territory, claims)
      { :error, _error } ->
        {:error,  :authentication_required}
    end
  end

  defp check_territory_validity(target_territory, claims) do
    case Map.keys(target_territory) do
      ["hash", "radius"] ->
        targeth3index =
          target_territory["hash"]
          |> to_charlist()
          |> :h3.from_string()

        claims["territory"]
        |> Map.values()
        |> Enum.map(fn %{"hash" => jwt_hash, "radius" => jwt_radius} ->
          :h3.parent(targeth3index, jwt_radius)
          |> :h3.to_string()
          |> Kernel.==(to_charlist(jwt_hash))
        end)
        |> Enum.member?(true)

      _ -> false
    end
  end
end
