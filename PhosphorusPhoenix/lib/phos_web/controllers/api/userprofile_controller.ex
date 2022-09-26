defmodule PhosWeb.API.UserProfileController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.{User, User_Public_Profile}
  alias PhosWeb.Util.Migrator

  action_fallback PhosWeb.API.FallbackController

  def index(conn, _params) do
    user_profile = Users.list_users()
    render(conn, "index.json", user_profile: user_profile)
  end
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/orbs'

  def show(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    render(conn, "show.json", user_profile: user)
  end
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/orbs/a4519fe0-70ec-42e7-86f3-fdab1ef8ca23'

  def update(conn, %{"id" => id} = params) do
    user = Users.get_user!(id)
    params = Map.delete(params, "id")
    params =
      for {key, val} <- params, into: %{}, do: {String.to_atom(key), val}

    with {:ok, %User{} = user} <- Users.update_user_profile(user, params) do
      render(conn, "show.json", user_profile: user)
    end
  end

  def show_user_media(conn, %{"id" => id}) do
    json(conn, %{payload: Phos.Orbject.S3.get!("USR", id, "150x150") })
  end


end
