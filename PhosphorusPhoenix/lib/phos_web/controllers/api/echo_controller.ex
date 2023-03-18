defmodule PhosWeb.API.EchoController do
  use PhosWeb, :controller
  use Phos.ParamsValidator, [
    :id, :message, :user_source_id, :orb_subject_id, :user_destination_id, :rel_subject_id, :media
  ]
  alias Phos.Message
  alias Phos.Message.Memory
  action_fallback PhosWeb.API.FallbackController

  def index_relations(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, %{"page" => page}),
    do: render(conn, :paginated, reveries: Message.last_messages_by_relation(id, page))

  def show_relations_jump_orbs(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => rel_id, "page" => page}),
    do: render(conn, :paginated, memories: Message.last_messages_by_orb_within_relation({rel_id, your_id}, page))

  def show_relations_jump_orbs(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => rel_id, "cursor" => cursor, "asc" => "true"}),
    do: render(conn, :paginated, memories: Message.last_messages_by_orb_within_relation({rel_id, your_id}, [filter: String.to_integer(cursor) |> DateTime.from_unix!(:millisecond), asc: true]))

  def show_relations_jump_orbs(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => rel_id, "cursor" => cursor}),
    do: render(conn, :paginated, memories: Message.last_messages_by_orb_within_relation({rel_id, your_id}, [filter: String.to_integer(cursor) |> DateTime.from_unix!(:millisecond)]))

  def show_relations(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => rel_id, "page" => page}),
    do: render(conn, :paginated, memories: Message.list_messages_by_relation({rel_id, your_id}, page))

  def show_relations(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => rel_id, "cursor" => cursor, "asc" => "true"}),
    do: render(conn, :paginated, memories: Message.list_messages_by_relation({rel_id, your_id}, [filter: String.to_integer(cursor) |> DateTime.from_unix!(:millisecond), asc: true]))

  def show_relations(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => rel_id, "cursor" => cursor}),
    do: render(conn, :paginated, memories: Message.list_messages_by_relation({rel_id, your_id}, [filter: String.to_integer(cursor) |> DateTime.from_unix!(:millisecond)]))

  def show_orbs(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => orb_id, "page" => page}),
    do: render(conn, :paginated, memories: Message.list_messages_by_orb({orb_id, your_id}, page))

  def show(conn = %{assigns: %{current_user: _user}}, %{"id" => id}) do
    with %Memory{} = memory <-  Message.get_memory!(id) do
      render(conn, "show.json", memory: memory)
    else
      nil -> {:error, :not_found}
    end
  end

  # # media support
  def create(conn = %{assigns: %{current_user: user}}, params = %{"media" => [_|_] = media}) do
    with {:ok, attrs} <- memory_constructor(user, params),
         {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: attrs["id"], archetype: "MEM", media: media}),
         {:ok, %Memory{} = memory} <- Message.create_message(%{attrs | "media" => true}) do

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/memland/memories/#{memory.id}")
      |> render(:show, memory: memory, media: media)
    end
  end

  # # Target Insert
  # # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -d '{"geohash": {"target": 8, "central_geohash": 623275816647884799}, "title": "toa payoh memory 4", "active": "true", "media": "false", "expires_in": "10000"}' -X POST 'http://localhost:4000/api/echos'
  def create(conn = %{assigns: %{current_user: user}}, params) do
    with {:ok, attrs} <- memory_constructor(user, params),
         {:ok, %Memory{} = memory} <- Message.create_message(attrs) do

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/memland/memories/#{memory.id}")
      |> render(:show, memory: memory)

    end
  end

  def update(%Plug.Conn{assigns: %{current_user: %{id: user_id}}} = conn , %{"id" => id} = params) do
    memory = Message.get_memory!(id)
    with true <- memory.initiator.id == user_id,
         {:ok, attrs} <- memory_constructor(user_id, params),
         {:ok, %Memory{} = memory} <- Message.update_memory(memory, attrs) do
      conn
      |> put_status(:ok)
      |> put_resp_header("location", ~p"/api/memland/memories/#{memory.id}")
      |> render(:show, memory: memory)
    else
      false -> {:error, :unauthorized}
    end
  end

  def update_reverie(%Plug.Conn{assigns: %{current_user: %{id: user_id}}} = conn , %{"id" => id} = attrs) do
    reverie = Message.get_reverie!(id)
    with true <- reverie.user_destination_id == user_id,
         {:ok, %Message.Reverie{} = reverie} <- Message.update_reverie(reverie, attrs) do
      conn
      |> put_status(:ok)
      #|> put_resp_header("location", ~p"/api/memland/reveries/#{reverie.id}")
      |> render(:show, reverie: reverie)
    else
      false -> {:error, :unauthorized}
    end
  end

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X PUT -d '{"active": "false"}' http://localhost:4000/api/echos/fe1ac6b5-3db3-49e2-89b2-8aa30fad2578

  def delete(%Plug.Conn{assigns: %{current_user: %{id: user_id}}} = conn, %{"id" => id}) do
    memory = Message.get_memory!(id)

    with true <- memory.initiator.id == user_id,
         {:ok, %Memory{}} <- Message.delete_memory(memory) do
      send_resp(conn, :no_content, "")
    end
  end

  defp memory_constructor(user, params) do
    constructor = sanitize(params)
    try do
      {:ok, constructor |> Map.put("user_source_id", user.id)}
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  def parse_params("id", data) when is_nil(data), do: Ecto.UUID.generate()
end
