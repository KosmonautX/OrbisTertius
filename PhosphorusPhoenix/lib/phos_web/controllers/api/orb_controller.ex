defmodule PhosWeb.API.OrbController do
  use PhosWeb, :controller

  alias Phos.Action
  alias Phos.Action.Orb
  alias PhosWeb.Utility.Encoder

  action_fallback PhosWeb.API.FallbackController

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/comments'

  def index(conn, _params) do
    orbs = Action.list_orbs()
    render(conn, "index.json", orbs: orbs)
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
  # def create(conn, orb_params) do
  #   orb_id = Ecto.UUID.generate()
  #   # Process latlon value to x7 h3 indexes
  #   orb_params = try do
  #     central_hash = List.last(socket.assigns.addresses[String.to_atom(orb_params["location"])])
  #     |> :h3.parent(String.to_integer(orb_params["radius"]))
  #     geohashes = central_hash
  #     |> :h3.k_ring(1)
  #     orb_params
  #     |> Map.put("central_geohash", central_hash)
  #     |> Map.put("geolocation", geohashes)
  #   rescue
  #     ArgumentError -> orb_params |> Map.put("geolocation", [])
  #   end
  #   orb_params = Map.put(orb_params, "id", orb_id)

  #   with {:ok, %Orb{} = orb} <- Action.create_orb(orb_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.orb_path(conn, :show, orb))
  #     |> render("show.json", orb: orb)
  #   end
  # end
  # curl -H "Content-Type: application/json" -X POST -d '{"comment": {"id": "51f7a029-2023-4da1-8ff8-7981ac81b7a8", "body": "Hi comment", "path": "51f7a029", "active": "true", "orb_id": "a003b89a-74a5-448a-9b7a-94a4e2324cb3", "initiator_id": "d9476604-f725-4068-9852-1be66a046efd"}}' http://localhost:4000/api/comments

  def show(conn, %{"id" => id}) do
    orb = Action.get_orb!(id)
    render(conn, "show.json", orb: orb)
  end
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/orbs/a4519fe0-70ec-42e7-86f3-fdab1ef8ca23'

  def update(conn, %{"id" => id, "orb" => orb_params}) do
    orb = Action.get_orb!(id)

    with {:ok, %Orb{} = orb} <- Action.update_orb(orb, orb_params) do
      render(conn, "show.json", orb: orb)
    end
  end
  # curl -H "Content-Type: application/json" -X PUT -d '{"comment": {"active": "false"}}' http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b
  # curl -H "Content-Type: application/json" -X PUT -d '{"comment": {"body": "HENLOO!"}}' http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b

  def delete(conn, %{"id" => id}) do
    orb = Action.get_orb!(id)

    with {:ok, %Orb{}} <- Action.delete_orb(orb) do
      send_resp(conn, :no_content, "")
    end
  end

end
