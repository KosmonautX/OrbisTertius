defmodule PhosWeb.API.OrbController do
  use PhosWeb, :controller
  use Phos.ParamsValidator, [
    :id, :locations, :title, :media, :initiator_id, :traits, :active,
    :source,  payload: [:when, :where, :info, :tip, :inner_title], rename: [:expires_in, :extinguish]
  ]

  alias Phos.Action
  alias Phos.Action.Orb

  action_fallback PhosWeb.API.FallbackController

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/comments'

  def index(conn, _params) do
    orbs = Action.list_orbs()
    render(conn, :index, orbs: orbs)
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
         {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: attrs["id"], archetype: "ORB", media: media}),
         {:ok, %Orb{} = orb} <- Action.create_orb(%{attrs | "media" => true}) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/orbland/orbs/#{orb.id}")
      |> render(:show, orb: orb, media: media)
    end
  end

  # Target Insert
  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -d '{"geohash": {"target": 8, "central_geohash": 623275816647884799}, "title": "toa payoh orb 4", "active": "true", "media": "false", "expires_in": "10000"}' -X POST 'http://localhost:4000/api/orbs'
  def create(conn = %{assigns: %{current_user: user}}, params) do

    with {:ok, attrs} <- orb_constructor(user, params),
         {:ok, %Orb{} = orb} <- Action.create_orb(attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/orbland/orbs/#{orb.id}")
      |> render(:show, orb: orb)
    end
  end

  defp orb_constructor(user, params) do
    constructor = sanitize(params)
    try do
      options = case params do
        # Normal post, accepts a map containing target and central geohash
        # Generates 7x given the target
        %{"geolocation" => %{"central_geohash" => central_geohash}} ->
          locations = central_geohash |> :h3.parent(8) |> :h3.k_ring(1) |> Enum.map(&Map.new([{"id", &1}]))
          %{"locations" => locations, "central_geohash" => central_geohash}

        %{"geolocation" => %{"geohashes" => hashes}} ->
          locations = Enum.map(hashes, &Map.new([{"id", &1}]))
          %{"locations" => locations, "central_geohash" => List.first(hashes)}

        _ -> %{}
      end
      |> Map.put("initiator_id", user.id)
      {:ok, Map.merge(constructor, options)}
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  def show(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
    with %Orb{} = orb <-  Action.get_orb(id, user.id) do
      render(conn, "show.json", orb: orb)
    else
      nil -> {:error, :not_found}
    end
  end

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/orbs/a4519fe0-70ec-42e7-86f3-fdab1ef8ca23'
  #

  def show_history(conn, %{"id" => id, "page" => page, "traits" => traits}) do
    orbs = Action.orbs_by_initiators([id], page, %{"traits" => traits})
    render(conn, :paginated, orbs: orbs)
  end

  def show_history(conn, %{"id" => id, "page" => page}) do
    orbs = Action.orbs_by_initiators([id], page)
    render(conn, :paginated, orbs: orbs)
  end

  def show_history(conn, %{"id" => id}) do
    orbs = Action.orbs_by_initiators([id], 1)
    render(conn, :paginated, orbs: orbs)
  end

  def show_territory(%{assigns: %{current_user: user}} = conn, %{"id" => hashes, "page" => page, "traits" => trait}) do
    try do
      geohashes = String.split(hashes, ",")
      |> Enum.map(fn hash ->
        Enum.map([8, 9, 10], &(:h3.parent(String.to_integer(hash), &1))) end)
        |> List.flatten()
        |> Enum.uniq()

      traits = String.split(trait, ",") |> Enum.uniq()
      loc_orbs = Action.orbs_by_geotraits({geohashes, user.id}, traits, [page: page])
      render(conn, :paginated, orbs: loc_orbs)
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  def show_territory(%{assigns: %{current_user: user}} = conn, %{"id" => hashes, "cursor" => cursor}) do
    geohashes = String.split(hashes, ",")
    |> Enum.map(fn hash -> String.to_integer(hash) |> :h3.parent(8) end)
    |> Enum.uniq()
    loc_orbs = Action.orbs_by_geohashes({geohashes, user.id} ,
      [filter: String.to_integer(cursor) |> DateTime.from_unix!(:second)])
    render(conn, :paginated, orbs: loc_orbs)
  end

  def show_territory(%{assigns: %{current_user: user}} = conn, %{"id" => hashes, "page" => page}) do
    geohashes = String.split(hashes, ",")
    |> Enum.map(fn hash -> String.to_integer(hash) |> :h3.parent(8) end)
    |> Enum.uniq()
    loc_orbs = Action.orbs_by_geohashes({geohashes, user.id}, [page: page])
    render(conn, :paginated, orbs: loc_orbs)
  end

  def show_territory(%{assigns: %{current_user: user}} = conn, %{"id" => hashes}) do
    geohashes = String.split(hashes, ",")
    |> Enum.map(fn hash -> String.to_integer(hash) |> :h3.parent(8) end)
    |> Enum.uniq()
    loc_orbs = Action.orbs_by_geohashes({geohashes, user.id}, 1)
    render(conn, :paginated, orbs: loc_orbs)
  end

  def show_friends(conn = %{assigns: %{current_user: %{id: id}}}, %{"page" => page}) do
    orbs = Phos.Action.orbs_by_friends(id, page)
    render(conn, :paginated, orbs: orbs)
  end

  def show_friends(conn = %{assigns: %{current_user: %{id: id}}}, _params) do
    orbs = Phos.Action.orbs_by_friends(id, 1)
    render(conn, :paginated, orbs: orbs)
  end


  def update(conn = %{assigns: %{current_user: user}}, params = %{"id" => id, "media" => [_|_] = media}) do
    orb = Action.get_orb!(id)
    with true <- orb.initiator.id == user.id,
         {:ok, attrs} <- orb_constructor(user, params),
         {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: id, archetype: "ORB", media: media}),
         {:ok, %Orb{} = orb} <- Action.update_orb(orb, %{attrs | "media" => true}) do
      conn
      |> put_status(:ok)
      |> put_resp_header("location", ~p"/api/orbland/orbs/#{orb.id}")
      |> render(:show, orb: orb, media: media)

    else
      false -> {:error, :unauthorized}
    error -> error
    end
  end


  def update(conn = %{assigns: %{current_user: user}}, %{"id" => id} = params) do
    orb = Action.get_orb!(id)
    with true <- orb.initiator.id == user.id,
         {:ok, attrs} <- orb_constructor(user, params),
         {:ok, %Orb{} = orb} <- Action.update_orb(orb, attrs) do
      conn
      |> put_status(:ok)
      |> put_resp_header("location", ~p"/api/orbland/orbs/#{orb.id}")
      |> render(:show, orb: orb)
    else
      false -> {:error, :unauthorized}
    end
  end

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X PUT -d '{"active": "false"}' http://localhost:4000/api/orbs/fe1ac6b5-3db3-49e2-89b2-8aa30fad2578

  def delete(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
    orb = Action.get_orb!(id)
    with true <- orb.initiator.id == user.id,
         {:ok, %Orb{}} <- Action.delete_orb(orb) do
      send_resp(conn, :no_content, "")
    else
      false -> {:error, :unauthorized}
    end
  end

  def parse_params("id", data) when is_nil(data), do: Ecto.UUID.generate()
  def parse_params("active", data) when is_nil(data), do: true
  def parse_params("source", _), do: :api
  def parse_params("extinguish", data) when not is_nil(data) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(String.to_integer(data))
  end
end
