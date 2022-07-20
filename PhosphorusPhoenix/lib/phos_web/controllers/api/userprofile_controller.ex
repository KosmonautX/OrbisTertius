defmodule PhosWeb.API.UserProfileController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.{User}

  action_fallback PhosWeb.API.FallbackController

  def index(conn, _params) do
    user_profile = Users.list_users_pub()
    render(conn, "index.json", user_profile: user_profile)
  end
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/orbs'

#   @doc """
#   Creates a orb.

#   ## Examples

#       iex> create_orb(%{field: value})
#       {"data": %Orb{}}

#       iex> create_orb(%{field: bad_value})
#       ""

#   """

# Target Insert
# curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -d '{"geohash": {"target": 8, "central_geohash": 623275816647884799}, "title": "toa payoh orb 4", "active": "true", "media": "false", "expires_in": "10000"}' -X POST 'http://localhost:4000/api/orbs'

# Bulk Insert
# curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -d '{"geohash": [623275816647884799, 623275816649424895, 623275816649293823, 623275816647753727, 623275816647688191, 623275816647819263, 623275816648835071], "title": "toa payoh orb3", "active": "true", "media": "false", "expires_in": "10000"}' -X POST 'http://localhost:4000/api/orbs'
  # def create(conn, orb_params) do
  #   orb_params =
  #   case orb_params do
  #     # Normal post, accepts a map containing target and central geohash
  #     # Generates 7x given the target
  #     %{"geohash" => %{"central_geohash" => central_geohash}} ->
  #       %{
  #         "id" => Ecto.UUID.generate(),
  #         "geolocation" => central_geohash |> :h3.k_ring(1),
  #         "title" => orb_params["title"],
  #         "initiator_id" => conn.assigns.current_user["user_id"],
  #         "payload" => %{
  #           "when" => orb_params["when"],
  #           "where" => orb_params["where"],
  #           "info" => orb_params["info"],
  #           "tip" => orb_params["tip"],
  #           "inner_title" => orb_params["inner_title"],
  #         },
  #         "media" => orb_params["media"],
  #         "source" => :web,
  #         "extinguish" => NaiveDateTime.utc_now() |> NaiveDateTime.add(String.to_integer(orb_params["expires_in"])),
  #         "central_geohash" => central_geohash,
  #         "traits" => orb_params["traits"],
  #         "active" => orb_params["active"]
  #       }

  #     # Bulk post, accepts list of h3 indices
  #     %{"geohash" => [head | tail]} ->
  #       %{
  #         "id" => Ecto.UUID.generate(),
  #         "geolocation" => [head] ++ tail,
  #         "title" => orb_params["title"],
  #         "initiator_id" => conn.assigns.current_user["user_id"],
  #         "payload" => %{
  #           "when" => orb_params["when"],
  #           "where" => orb_params["where"],
  #           "info" => orb_params["info"],
  #           "tip" => orb_params["tip"],
  #           "inner_title" => orb_params["inner_title"],
  #         },
  #         "media" => orb_params["media"],
  #         "source" => :web,
  #         "extinguish" => NaiveDateTime.utc_now() |> NaiveDateTime.add(String.to_integer(orb_params["expires_in"])),
  #         "central_geohash" => head,
  #         "traits" => orb_params["traits"],
  #         "active" => orb_params["active"]
  #       }
  #       _ -> {:error, :unprocessable_entity}
  #       %{}
  #   end

  #   with {:ok, %Orb{} = orb} <- Action.create_orb(orb_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.orb_path(conn, :show, orb))
  #     |> render("show.json", orb: orb)
  #   end
  # end

  def show(conn, %{"id" => id}) do
    user_profile = Users.get_pub_profile_by_id(id)
    render(conn, "show.json", user_profile: user_profile)
  end
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/orbs/a4519fe0-70ec-42e7-86f3-fdab1ef8ca23'

  def update(conn, %{"id" => id} = profile_params) do
    user = Users.get_user!(id)

    with {:ok, %User{} = user} <- Users.update_pub_user(user, profile_params) do
      render(conn, "show.json", user_profile: user)
    end
  end
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X PUT -d '{"active": "false"}' http://localhost:4000/api/orbs/fe1ac6b5-3db3-49e2-89b2-8aa30fad2578

  def delete(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    with {:ok, %User{}} <- Users.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  def show_user_media(conn, %{"id" => id}) do
    json(conn, %{payload: Phos.Orbject.S3.get!("USR", id, "150x150") })
  end


end
