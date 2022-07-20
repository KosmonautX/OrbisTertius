defmodule PhosWeb.API.UserProfileController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.{User}

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

  # def create(conn, comment_params) do
  #   case comment_params do
  #     # Create root comment flow
  #     %{"orb_id" => orb_id} ->
  #       comment_id = Ecto.UUID.generate()
  #       comment_params = %{"id" => comment_id,
  #                          "orb_id" => orb_id,
  #                          "initiator_id" => conn.assigns.current_user["user_id"],
  #                          "path" => Encoder.encode_lpath(comment_id),
  #                          "body" => comment_params["body"]}

  #       with {:ok, %Comment{} = comment} <- Comments.create_comment(comment_params) do
  #         conn
  #         |> put_status(:created)
  #         |> put_resp_header("location", Routes.comment_path(conn, :show, comment))
  #         |> render("show.json", comment: comment)
  #       end
  #       # Create child comment flow
  #       %{"parent_id" => parent_id} ->
  #       parent_comment = Comments.get_comment!(parent_id)
  #       comment_id = Ecto.UUID.generate()
  #       comment_params = %{"id" => comment_id,
  #                          "orb_id" => parent_comment.orb_id,
  #                          "parent_id" => parent_comment.id,
  #                          "initiator_id" => conn.assigns.current_user["user_id"],
  #                          "path" => Encoder.encode_lpath(comment_id, to_string(parent_comment.path)),
  #                          "body" => comment_params["body"]}

  #       with {:ok, %Comment{} = comment} <- Comments.create_comment(comment_params) do
  #         conn
  #         |> put_status(:created)
  #         |> put_resp_header("location", Routes.comment_path(conn, :show, comment))
  #         |> render("show.json", comment: comment)
  #       end
  #   end
  # end

  def update(conn, %{"id" => id} = profile_params) do
    user = Users.get_user!(id)

    with {:ok, %User{} = user} <- Users.update_pub_user(user, profile_params) do
      render(conn, "show.json", user_profile: user)
    end
  end
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
