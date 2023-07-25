defmodule PhosWeb.Util.Geographer do
  alias Phos.Users
  alias Phos.Users.{User}
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

  def update_territory(user_id, territory) do
    user = Users.get_territorial_user!(user_id)
    with [_ | _]<- validate_territory(user, territory),
         payload = %{"private_profile" => _ , "personal_orb" => _} <- parse_territory(user, territory),
         {:ok, %User{} = user} <- Users.update_territorial_user(user, payload) do
          user
    else
      [] ->
        user
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def validate_territory(%{private_profile: %{geolocation: past_territory}}, wished_territory) when is_list(wished_territory) do
    past = past_territory |> Enum.into(%{},fn loc -> {loc.id, loc} end)
    wished_territory |> Enum.reject(fn wish -> !(!Map.has_key?(past, wish["id"]) or (past[wish["id"]].geohash != wish["geohash"]))   end)
  end

  def validate_territory(%{private_profile: _}, wished_territory) when is_list(wished_territory) do
    wished_territory
  end

  def parse_territory(user, wished_territory) when is_list(wished_territory) do
    try do
      present_territory = wished_territory
      |> Enum.map(fn loc -> :h3.parent(loc["geohash"], 11) end)
      |> Enum.map(fn hash -> :h3.parent(hash, 8) |> :h3.k_ring(1) end)
      |>  List.flatten() |> Enum.uniq()

      # Places does not include the live location of the user
      places = wished_territory
      |> Enum.map(fn loc ->
        hash = :h3.parent(loc["geohash"], 8)
        %{"geohash" => hash,
          "id" => loc["id"],
          "location_description" => hash |> Phos.Mainland.World.locate()}
      end)
      |> Enum.reject(fn loc -> loc["id"] == "live" end)

      %{"private_profile" => %{"user_id" => user.id, "geolocation" => wished_territory},
        "public_profile" => %{"territories" => present_territory, "places" => places},
        "personal_orb" => %{
          "id" => (if is_nil(user.personal_orb), do: Ecto.UUID.generate(), else: user.personal_orb.id),
          "active" => true,
          "userbound" => true,
          "initiator_id" => user.id,
          "locations" =>  present_territory |> Enum.map(fn hash -> %{"id" => hash} end)
        }
      }
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  # Returns true if target territory's parent = socket's claim territory
  def check_territory?(socket, target_territory) do
    case Auth.validate_user(socket.assigns.session_token) do
      {:ok , claims} ->
        case Map.keys(target_territory) do
          ["hash", "radius"] ->
            targeth3index =
              target_territory["hash"]
              |> to_charlist()
              |> :h3.from_string()

            claims["territory"]
            |> Map.values()
            |> Enum.map(fn %{"hash" => jwt_hash, "radius" => jwt_radius} ->
              if (:h3.parent(targeth3index, jwt_radius) |> :h3.to_string()) == to_charlist(jwt_hash) do
                true
              else
                false
              end
            end)
            |> Enum.member?(true)

          _ -> false
        end
      { :error, _error } ->
        {:error,  :authentication_required}
    end
  end
end
