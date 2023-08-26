defmodule PhosWeb.API.UserProfileController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.User
  alias Phos.Orbject
  alias PhosWeb.Util.Geographer

  action_fallback PhosWeb.API.FallbackController

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/userland/self'

  def show(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, %{"id" => user_id}) do
    with %User{} = user <-  Users.get_public_user(user_id, id) do
      render(conn, :show, user_profile: user)
    else
      nil -> {:error, :not_found}
    end
  end

  def show_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, _params) do
    user = Users.get_user!(id)
    render(conn, :show, my_profile: user)
  end

  def update_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, %{"media" => [_|_] = media} = params) do
    user = Users.get_user!(id)
    with {:ok, media} <- Orbject.Structure.apply_media_changeset(%{id: id, archetype: "USR", media: media}),
         {:ok, %User{} = user} <- Users.update_user(user, Map.put(profile_constructor(user, params),"media", true)) do
      render(conn, :show, user_profile: user, media: media)
    end
  end


  def update_self(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, params) do
    user = Users.get_user!(id)
    case Users.update_user(user, profile_constructor(user, params)) do
      {:ok, %User{} = updated_user} -> render(conn, :show, user_profile: updated_user)
      {:error, changeset} -> {:error, changeset}
    end
  end


  def update_territory(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, %{"territory" => territory =[_ | _]}) do
    user = Users.get_territorial_user!(id)
    with [_ | _]<- validate_territory(user, territory),
         payload = %{"private_profile" => _ , "personal_orb" => _} <- parse_territory(user, territory),
         {:ok, %User{} = user} <- Users.update_territorial_user(user, payload) do
      render(conn, :show, user_profile: user)
    else
      [] ->
        render(conn, :show, user_profile: user)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp validate_territory(%{private_profile: %{geolocation: _past_territory}} = user, wished_territory) when is_list(wished_territory) do
    Geographer.validate_territory(user, wished_territory)
  end

  defp validate_territory(%{private_profile: _} = user, wished_territory) when is_list(wished_territory) do
    Geographer.validate_territory(user, wished_territory)
  end

  defp parse_territory(user, wished_territory) when is_list(wished_territory) do
    Geographer.parse_territory(user, wished_territory)
  end

  def update_beacon(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"fcm_token" => token, "beacon" => %{"scope" => false}} = params) do
    with true <- !Fcmex.unregistered?(token),
         {:ok, %{}} <- Fcmex.Subscription.unsubscribe("USR." <> user.id, token),
         {:ok, %User{} = user_integration} <- Users.update_integrations_user(user, %{"integrations" => params}) do
      render(conn, :show, integration: user_integration)
    else
      false -> {:error, :unprocessable_entity}
    end
  end

  def update_beacon(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"fcm_token" => token} = params) do
    with true <- !Fcmex.unregistered?(token),
         {:ok, %{}} <- Fcmex.Subscription.subscribe("USR." <> user.id, token),
         {:ok, %User{} = user_integration} <- Users.update_integrations_user(user, %{"integrations" => params}) do
      render(conn, :show, integration: user_integration)
    else
      false -> {:error, :unprocessable_entity}
    end
  end

  defp purge_nil(map), do: map |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()

  defp profile_constructor(user, params) do
    %{
      "username" => params["username"],
      "public_profile" => %{"birthday" => (if params["birthday"], do: params["birthday"]|> DateTime.from_unix!() |> DateTime.to_naive()),
                            "bio" => params["bio"],
                            "public_name" => params["public_name"],
                            "occupation" => params["occupation"],
                            "traits" => params["traits"],
                            "profile_pic" => params["profile_pic"],
                            "banner_pic" => params["banner_pic"]
                           } |> purge_nil(),
      "personal_orb" => %{"id" => (if is_nil(user.personal_orb), do: Ecto.UUID.generate(), else: user.personal_orb.id),
                          "userbound" => true,
                          "initiator_id" => user.id,
                          "traits" => params["traits"],
                          "title" => (if !is_nil(params["soulorb"]), do: params["soulorb"]["title"]),
                          "payload" => (if !is_nil(params["soulorb"]), do: params["soulorb"]["payload"])
                         } |> purge_nil()
    } |> purge_nil()
  end

 end
