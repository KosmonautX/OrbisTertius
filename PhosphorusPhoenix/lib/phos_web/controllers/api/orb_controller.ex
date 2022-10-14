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

# Media Strategy
 def create(conn = %{assigns: %{current_user: user}}, params = %{"media" => [_|_] = media}) do

    with {:ok, attrs} <- orb_constructor(user, params),
         {:ok, media} <- Phos.Orbject.Structure.apply_orb_changeset(%{id: attrs["id"], archetype: "ORB", media: media}),
         {:ok, %Orb{} = orb} <- Action.create_orb(%{attrs | "media" => true}) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.orb_path(conn, :show, orb))
      |> render("show.json", orb: orb, media: media)
    end
  end

  # Target Insert
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -d '{"geohash": {"target": 8, "central_geohash": 623275816647884799}, "title": "toa payoh orb 4", "active": "true", "media": "false", "expires_in": "10000"}' -X POST 'http://localhost:4000/api/orbs'
  def create(conn = %{assigns: %{current_user: user}}, params) do

    with {:ok, attrs} <- orb_constructor(user, params),
         {:ok, %Orb{} = orb} <- Action.create_orb(attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.orb_path(conn, :show, orb))
      |> render("show.json", orb: orb)
    end
  end

  defp orb_constructor(user, params) do
    try do
      case params do
        # Normal post, accepts a map containing target and central geohash
        # Generates 7x given the target
        %{"geolocation" => %{"central_geohash" => central_geohash}} ->
          {:ok,
           %{
             "id" => Ecto.UUID.generate(),
             "locations" => central_geohash |> :h3.parent(8) |> :h3.k_ring(1) |> Enum.map(fn hash -> %{"id" => hash} end),
             "title" => params["title"],
             "media" => params["media"],
             "initiator_id" => user.id,
             "payload" => %{
               "when" => params["when"],
               "where" => params["where"],
               "info" => params["info"],
               "tip" => params["tip"],
               "inner_title" => params["inner_title"],
             } |> purge_nil(),
             "source" => :api,
             "extinguish" => NaiveDateTime.utc_now() |> NaiveDateTime.add(String.to_integer(params["expires_in"])),
             "central_geohash" => central_geohash,
             "traits" => params["traits"],
             "active" => params["active"] || true
           } |> purge_nil()
          }

        %{"geolocation" => %{"geohashes" => hashes}} ->
          {:ok,
           %{
             "id" => Ecto.UUID.generate(),
             "locations" => hashes|> Enum.map(fn hash -> %{"id" => hash} end),
             "title" => params["title"],
             "media" => params["media"],
             "initiator_id" => user.id,
             "payload" => %{
               "when" => params["when"],
               "where" => params["where"],
               "info" => params["info"],
               "tip" => params["tip"],
               "inner_title" => params["inner_title"],
             } |> purge_nil(),
             "source" => :api,
             "extinguish" => NaiveDateTime.utc_now() |> NaiveDateTime.add(String.to_integer(params["expires_in"])),
             "central_geohash" => List.first(hashes),
             "traits" => params["traits"],
             "active" => params["active"] || true
           } |> purge_nil()
          }


        _ ->
          {:ok,
           %{
             "id" => params["id"] || Ecto.UUID.generate(),
             "title" => params["title"],
             "media" => params["media"],
             "initiator_id" => user.id,
             "payload" => %{
               "when" => params["when"],
               "where" => params["where"],
               "info" => params["info"],
               "tip" => params["tip"],
               "inner_title" => params["inner_title"],
             } |> purge_nil(),
             "source" => :api,
             "extinguish" => (if params["expires_in"], do: NaiveDateTime.utc_now() |> NaiveDateTime.add(String.to_integer(params["expires_in"]))),
             "traits" => params["traits"],
             "active" => params["active"] || true
           } |> purge_nil()
          }
      end
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  def show(conn, %{"id" => id}) do
    orb = Action.get_orb!(id)
    render(conn, "show.json", orb: orb)
  end
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/orbs/a4519fe0-70ec-42e7-86f3-fdab1ef8ca23'
  #
  def show_history(conn, %{"id" => id, "page" => page}) do
    orbs = Action.orbs_by_initiators([id], page)
    render(conn, "paginated.json", orbs: orbs)
  end

  def show_history(conn, %{"id" => id}) do
    orbs = Action.orbs_by_initiators([id], 1)
    render(conn, "paginated.json", orbs: orbs)
  end

  def show_territory(conn, %{"id" => hash, "page" => page}) do
    loc_orbs = Action.orbs_by_geohashes([String.to_integer(hash) |> :h3.parent(8)], page)
    render(conn, "paginated.json", locations: loc_orbs)
  end

  def show_territory(conn, %{"id" => hash}) do
    loc_orbs = Action.orbs_by_geohashes([String.to_integer(hash) |> :h3.parent(8)], 1)
    render(conn, "paginated.json", locations: loc_orbs)
  end

  def show_friends(conn = %{assigns: %{current_user: %{id: id}}}, %{"page" => page}) do
    friends = Phos.Users.friends(id) |> Enum.map(&(&1.id))
    orbs = Phos.Action.orbs_by_initiators([id | friends], page)
    render(conn, "paginated.json", orbs: orbs)
  end

  def show_friends(conn = %{assigns: %{current_user: %{id: id}}}, _params) do
    friends = Phos.Users.friends(id) |> Enum.map(&(&1.id))
    orbs = Phos.Action.orbs_by_initiators([id | friends], 1)
    render(conn, "paginated.json", orbs: orbs)
  end


   def update(conn = %{assigns: %{current_user: user}}, params = %{"id" => id, "media" => [_|_] = media}) do
    orb = Action.get_orb!(id)
    with true <- orb.initiator.id == user.id,
         {:ok, attrs} <- orb_constructor(user, params),
         {:ok, media} <- Phos.Orbject.Structure.apply_orb_changeset(%{id: id, archetype: "ORB", media: media}),
         {:ok, %Orb{} = orb} <- Action.update_orb(orb, %{attrs | "media" => true}) do
      conn
      |> put_status(:ok)
      |> put_resp_header("location", Routes.orb_path(conn, :show, orb))
      |> render("show.json", orb: orb, media: media)

    else
      false -> {:error, :unauthorized}
    end
  end


  def update(conn = %{assigns: %{current_user: user}}, %{"id" => id} = params) do
    orb = Action.get_orb!(id)
    with true <- orb.initiator.id == user.id,
         {:ok, attrs} <- orb_constructor(user, params),
         {:ok, %Orb{} = orb} <- Action.update_orb(orb, attrs) do
      conn
      |> put_status(:ok)
      |> put_resp_header("location", Routes.orb_path(conn, :show, orb))
      |> render("show.json", orb: orb)
    else
      false -> {:error, :unauthorized}
    end
  end

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X PUT -d '{"active": "false"}' http://localhost:4000/api/orbs/fe1ac6b5-3db3-49e2-89b2-8aa30fad2578

  def delete(conn, %{"id" => id}) do
    orb = Action.get_orb!(id)

    with {:ok, %Orb{}} <- Action.delete_orb(orb) do
      send_resp(conn, :no_content, "")
    end
  end

  defp purge_nil(map), do: map |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()

end
