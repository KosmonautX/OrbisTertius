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

  # Needs to include ALL publicprofile fields for request body
  # def update(conn, %{"id" => id} = profile_params) do
  #   case Ecto.UUID.cast(id) do
  #     {:ok, _} ->
  #       IO.inspect("im uuid")
  #       case Users.get_user!(id) do

  #         user = %User{} ->
  #           IO.inspect("lol12")
  #           with {:ok, %User{} = user} <- Users.update_pub_user(user, profile_params) do
  #             render(conn, "show.json", user_profile: user)
  #           end
  #         (Ecto.NoResultsError) ->
  #           IO.inspect("lol")
  #           {:error, :no_result}
  #         _ ->
  #           IO.inspect("lol 2314")
  #       end

  #     :error ->
  #       IO.inspect("Im fyr")
  #       case Users.get_user_by_fyr(id) do
  #         nil ->
  #           user = Migrator.user_profile(id) |> List.first()
  #           with {:ok, %User{} = user} <- Users.update_pub_user(user, profile_params) do
  #             render(conn, "show.json", user_profile: user)
  #           end

  #         Ecto.NoResultsError ->
  #           IO.inspect("lol")
  #           {:error, :no_result}

  #         user = %User{} ->
  #           with {:ok, %User{} = user} <- Users.update_pub_user(user, profile_params) do
  #             render(conn, "show.json", user_profile: user)
  #           end

  #         _ ->
  #           IO.inspect("LOL")
  #       end
  #   end
  # end

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X PUT -d '{"active": "false"}' http://localhost:4000/api/orbs/fe1ac6b5-3db3-49e2-89b2-8aa30fad2578

  # def delete(conn, %{"id" => id}) do
  #   user = Users.get_user!(id)

  #   with {:ok, %User{}} <- Users.delete_user(user) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end

  def show_user_media(conn, %{"id" => id}) do
    json(conn, %{payload: Phos.Orbject.S3.get!("USR", id, "150x150") })
  end


end
