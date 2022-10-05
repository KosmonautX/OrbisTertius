defmodule PhosWeb.API.UserProfileController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.User

  action_fallback PhosWeb.API.FallbackController

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/userland/self'

  def show_self(%Plug.Conn{assigns: %{current_user: %{"user_id" => id}}} = conn, _params) do
    user = Users.get_user!(id)
    render(conn, "show.json", user_profile: user)
  end


  def update_self(%Plug.Conn{assigns: %{current_user: %{"user_id" => id}}} = conn, params) do
    user = Users.get_user!(id)
    params = Map.delete(params, "id")
    with {:ok, %User{} = user} <- Users.update_user(user, params) do
      render(conn, "show.json", user_profile: user)
    end
  end


  def old_update_self(conn, %{"id" => id} = params) do
    user = Users.get_user!(id)
    params = Map.delete(params, "id")
    params =
      for {key, val} <- params, into: %{}, do: {String.to_atom(key), val}

    with {:ok, %User{} = user} <- Users.update_user_profile(user, params) do
      render(conn, "show.json", user_profile: user)
    end
  end

end
