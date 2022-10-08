defmodule PhosWeb.API.UserProfileController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.User
  alias Phos.Orbject

  action_fallback PhosWeb.API.FallbackController

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/userland/self'

  def show(%Plug.Conn{assigns: %{current_user: %{"user_id" => _id}}} = conn, %{"id" => user_id}) do
    user = Users.get_user!(user_id)
    render(conn, "show.json", user_profile: user)
  end

  def show_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, _params) do
    user = Users.get_user!(id)
    render(conn, "show.json", user_profile: user)
  end

  def update_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, params = %{"media" => [_,_] = forms}) do
    user = Users.get_user!(id)
    with {:ok, media} <- Ecto.Changeset.apply_action(Orbject.Structure.usermedia_changeset(forms), :orbject_fetch),
    {:ok, %User{} = user} <- Users.update_user(user, Map.put(profile_constructor(user, params),"media", true)) do
      render(conn, "show.json", user_profile: user, media: media)
    end
  end


  def update_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, params) do
    user = Users.get_user!(id)
    with {:ok, %User{} = user} <- Users.update_user(user, profile_constructor(user,params)) do
      render(conn, "show.json", user_profile: user)
    end
  end

  defp profile_constructor(user, params) do
    %{
      "username" => params["username"],
      "public_profile" => %{"birthday" => params["birthday"] |> DateTime.from_unix!() |> DateTime.to_naive(),
                           "bio" => params["bio"],
                           "public_name" => params["public_name"],
                           "occupation" => params["occupation"]},
      "personal_orb" => %{"id" => user.id,
                          "initiator_id" => user.id,
                          "traits" => ["personal" | params["traits"]]}
    }
  end



  def update_territory(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, territory =[_ | _]) do
    user = Users.get_user!(id)
    with [_,_]<- validate_territory(user, territory),
    payload = %{"private_profile" => _ , "personal_orb" => _} <- parse_territory(user, territory),
    {:ok, %User{} = user} <- Users.update_territorial_user(user, payload) do
      render(conn, "show.json", user_profile: user)
    else
      [] ->
        render(conn, "show.json", user_profile: user)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp validate_territory(%{private_profile: %{geolocation: past_territory}}, wished_territory) when is_list(wished_territory) do
    past = past_territory |> Enum.into(%{},fn loc -> {loc.id, loc} end)
    wished_territory |> Enum.reject(fn wish -> !(!Map.has_key?(past, wish["id"]) or (past[wish["id"]].geohash != wish["geohash"]))  end)
  end

  defp parse_territory(user, wished_territory) when is_list(wished_territory) do
    present_territory = wished_territory |> Enum.map(fn loc -> :h3.parent(loc.geohash, 11) end)
    %{"private_profile" => %{"user_id" => user.id, "geolocation" => wished_territory},
      "personal_orb" => %{
        "id" => user.id,
        "active" => true,
        "locations" => present_territory
        |> Enum.map(fn loc -> :h3.parent(loc["geohash"], 8) |> :h3.k_ring(1) end)
        |>  List.flatten() |> Enum.uniq() |> Enum.map(fn hash -> %{"id" => hash} end)
      }
    }
  end

end
