defmodule PhosWeb.Menshen.Auth do
  import Joken.Config

  def validate(token) do
    validator = default_claims(default_exp: 1212, iss: "Princeton")  |> add_claim("sub", nil, &(&1 == "ScratchBac"))
    Joken.verify_and_validate(validator,token,Joken.Signer.parse_config(:menshenSB))
  end

  # Returns true if target territory's parent = socket's claim territory
  def check_territory?(socket, target_territory)  when is_map(target_territory) do
    case validate(socket.assigns.session_token) do
      {:ok , claims} ->
        case Map.keys(target_territory) do
          ["hash", "radius"] ->
          target_territory["hash"]
            |> to_charlist()
            |> :h3.from_string()
            |> check_geoauth?(claims["territory"])

          ["latlon", "radius"] ->
          :h3.from_geo(target_territory["latlon"], target_territory["target"])
            |> check_geoauth?(claims["territory"])

          _ -> false
        end
      { :error, _error } ->
        {:error,  :authentication_required}
    end
  end

  defp check_geoauth?(target_hash, territories) do
    territories
    |> Map.values()
    |> Enum.map(fn %{"hash" => jwt_hash, "radius" => jwt_radius} ->
      if (:h3.parent(target_hash, jwt_radius) |> :h3.to_string()) == to_charlist(jwt_hash) do
        true
      else
        false
      end
    end)
    |> Enum.member?(true)
  end
end
