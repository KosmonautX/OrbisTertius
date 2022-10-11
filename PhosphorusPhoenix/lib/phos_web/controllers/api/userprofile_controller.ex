defmodule PhosWeb.API.UserProfileController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.User
  alias Phos.Orbject

  action_fallback PhosWeb.API.FallbackController

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/userland/self'

  def show(%Plug.Conn{assigns: %{current_user: %{"user_id" => _id}}} = conn, %{"id" => user_id}) do
    user = Users.get_public_user!(user_id)
    render(conn, "show.json", user_profile: user)
  end

  def show_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, _params) do
    user = Users.get_user!(id)
    render(conn, "show.json", user_profile: user)
  end

  def update_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, %{"media" => [_|_] = media} = params) do
    user = Users.get_user!(id)
    with {:ok, media} <- Orbject.Structure.apply_user_changeset(%{id: id, archetype: "USR", media: media}),
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
      "public_profile" => %{"birthday" => (if params["birthday"], do: params["birthday"]|> DateTime.from_unix!() |> DateTime.to_naive()),
                            "bio" => params["bio"],
                            "public_name" => params["public_name"],
                            "occupation" => params["occupation"],
                            "traits" => (if is_list(params["traits"]), do: params["traits"], else: [])
                           } |> purge_nil(),
      "personal_orb" => %{"id" => (if is_nil(user.personal_orb), do: Ecto.UUID.generate(), else: user.personal_orb.id),
                          "initiator_id" => user.id,
                          "traits" => (if is_list(params["traits"]), do: ["personal" | params["traits"]], else: ["personal"])}
    } |> purge_nil()
  end



  def update_territory(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, %{"territory" => territory =[_ | _]}) do
    user = Users.get_territorial_user!(id)
    with [_ | _]<- validate_territory(user, territory),
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
    wished_territory |> Enum.reject(fn wish -> !(!Map.has_key?(past, wish["id"]) or (past[wish["id"]].geohash != wish["geohash"]))   end)
  end

  defp validate_territory(%{private_profile: _}, wished_territory) when is_list(wished_territory) do
    wished_territory
  end

  defp parse_territory(user , wished_territory) when is_list(wished_territory) do
    try do
      present_territory = wished_territory |> Enum.map(fn loc -> :h3.parent(loc["geohash"], 11) end)
      %{"private_profile" => %{"user_id" => user.id, "geolocation" => wished_territory},
        "personal_orb" => %{
          "id" => (if is_nil(user.personal_orb), do: Ecto.UUID.generate(), else: user.personal_orb.id),
          "active" => true,
          "locations" => present_territory
          |> Enum.map(fn hash -> :h3.parent(hash, 8) |> :h3.k_ring(1) end)
          |>  List.flatten() |> Enum.uniq() |> Enum.map(fn hash -> %{"id" => hash} end)
        }
      }
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  defp purge_nil(map), do: map |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()

end
