defmodule PhosWeb.API.EchoController do
  use PhosWeb, :controller
  use Phos.ParamsValidator, [
    :id, :message, :user_source_id, :orb_subject_id, :user_destination_id, :rel_subject_id, :media
  ]
  alias Phos.Message
  alias Phos.Message.Echo
  alias Phos.Message.Memory
  action_fallback PhosWeb.API.FallbackController

  def show_last(%Plug.Conn{assigns: %{current_user: %{id: id}}} = conn, %{"page" => page}),
    do: render(conn, :paginated, echoes: Message.last_echoes(id, page))

  def show_others(%Plug.Conn{assigns: %{current_user: %{id: your_id}}} = conn, %{"id" => user_id, "page" => page}),
    do: render(conn, :paginated, echoes: Message.list_echoes_by_pair({user_id, your_id}, page))

  # def show(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
  #   with %Echo{} = echo <-  Action.get_echo(id, user.id) do
  #     render(conn, "show.json", echo: echo)
  #   else
  #     nil -> {:error, :not_found}
  #   end
  # end

  # # media support
  def create(conn = %{assigns: %{current_user: user}}, params = %{"media" => [_|_] = media}) do
    with {:ok, attrs} <- echo_constructor(user, params),
         {:ok, media} <- Phos.Orbject.Structure.apply_memory_changeset(%{id: attrs["id"], archetype: "MEM", media: media}),
         {:ok, %Memory{} = memory} <- Message.create_message(%{attrs | "media" => true}) do

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/memland/memories/#{memory.id}")
      |> render(:show, memory: memory, media: media)
    end
  end

  # # Target Insert
  # # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -d '{"geohash": {"target": 8, "central_geohash": 623275816647884799}, "title": "toa payoh echo 4", "active": "true", "media": "false", "expires_in": "10000"}' -X POST 'http://localhost:4000/api/echos'
  def create(conn = %{assigns: %{current_user: user}}, params) do
    with {:ok, attrs} <- echo_constructor(user, params),
         {:ok, %Memory{} = memory} <- Message.create_message(attrs) do

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/memland/memories/#{memory.id}")
      |> render(:show, memory: memory)
    end
  end

  def update(%Plug.Conn{assigns: %{current_user: %{id: user_id}}} = conn , %{"id" => id} = params) do
    echo = Message.get_echo!(id)
    with true <- echo.initiator.id == user_id,
         {:ok, attrs} <- echo_constructor(user_id, params),
         {:ok, %Echo{} = echo} <- Message.update_echo(echo, attrs) do
      conn
      |> put_status(:ok)
      |> put_resp_header("location", ~p"/api/echoland/echos/#{echo.id}")
      |> render(:show, echo: echo)
    else
      false -> {:error, :unauthorized}
    end
  end

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X PUT -d '{"active": "false"}' http://localhost:4000/api/echos/fe1ac6b5-3db3-49e2-89b2-8aa30fad2578

  def delete(%Plug.Conn{assigns: %{current_user: %{id: user_id}}} = conn, %{"id" => id}) do
    echo = Message.get_echo!(id)

    with true <- echo.initiator.id == user_id,
         {:ok, %Echo{}} <- Message.delete_echo(echo) do
      send_resp(conn, :no_content, "")
    end
  end


  defp echo_constructor(user, params) do
    constructor = sanitize(params)
    try do
      {:ok,
       constructor
       |> Map.put("user_source_id", user.id)
      }
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  def parse_params("id", data) when is_nil(data), do: Ecto.UUID.generate()
end
