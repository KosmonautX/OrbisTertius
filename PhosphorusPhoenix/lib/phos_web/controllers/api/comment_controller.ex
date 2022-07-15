defmodule PhosWeb.API.CommentController do
  use PhosWeb, :controller

  alias Phos.Comments
  alias Phos.Comments.Comment
  alias PhosWeb.Utility.Encoder

  action_fallback PhosWeb.API.FallbackController

  def index(conn, _params) do
    comments = Comments.list_comments()
    render(conn, "index.json", comments: comments)
  end
  # curl -H "Content-Type: application/json" -X GET http://localhost:4000/api/comments


  def create(conn, comment_params) do
    case comment_params do
      # Create root comment flow
      %{"orb_id" => orb_id} ->
        comment_id = Ecto.UUID.generate()
        comment_params =
          comment_params
          |> Map.put("id", comment_id)
          |> Map.put("orb_id", orb_id)
          |> Map.put("path", Encoder.encode_lpath(comment_id))

        with {:ok, %Comment{} = comment} <- Comments.create_comment(comment_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", Routes.comment_path(conn, :show, comment))
          |> render("show.json", comment: comment)
        end
      # Create child comment flow
      %{"parent_id" => parent_id} ->
        parent_comment = Comments.get_comment!(parent_id)
        comment_id = Ecto.UUID.generate()
        comment_params =
          comment_params
          |> Map.put("id", comment_id)
          |> Map.put("orb_id", parent_comment.orb_id)
          |> Map.put("path", Encoder.encode_lpath(comment_id, to_string(parent_comment.path)))

        with {:ok, %Comment{} = comment} <- Comments.create_comment(comment_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", Routes.comment_path(conn, :show, comment))
          |> render("show.json", comment: comment)
        end
    end
  end
  # curl -H "Content-Type: application/json" -X POST -d '{"comment": {"id": "51f7a029-2023-4da1-8ff8-7981ac81b7a8", "body": "Hi comment", "path": "51f7a029", "active": "true", "orb_id": "a003b89a-74a5-448a-9b7a-94a4e2324cb3", "initiator_id": "d9476604-f725-4068-9852-1be66a046efd"}}' http://localhost:4000/api/comments

  def show(conn, %{"id" => id}) do
    comment = Comments.get_comment!(id)
    render(conn, "show.json", comment: comment)
  end
  # curl -H "Content-Type: application/json" -X GET http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b

  def show_root(conn, %{"id" => id}) do
    comments = Comments.get_root_comments_by_orb(id)
    render(conn, "index.json", comments: comments)
  end
  # curl -H "Content-Type: application/json" -X GET http://localhost:4000/api/orbs/aa3609f6-a988-44c2-b9fa-67d8729639f7/root

  def show_ancestor(conn, %{"id" => orb_id, "cid" => cid}) do
    comment = Comments.get_comment!(cid)
    comments = Comments.get_ancestor_comments_by_orb(orb_id, to_string(comment.path))
    render(conn, "index.json", comments: comments)
  end

  def update(conn, %{"id" => id, "comment" => comment_params}) do
    comment = Comments.get_comment!(id)

    with {:ok, %Comment{} = comment} <- Comments.update_comment(comment, comment_params) do
      render(conn, "show.json", comment: comment)
    end
  end
  # curl -H "Content-Type: application/json" -X PUT -d '{"comment": {"active": "false"}}' http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b
  # curl -H "Content-Type: application/json" -X PUT -d '{"comment": {"body": "HENLOO!"}}' http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b

  def delete(conn, %{"id" => id}) do
    comment = Comments.get_comment!(id)

    with {:ok, %Comment{}} <- Comments.delete_comment(comment) do
      send_resp(conn, :no_content, "")
    end
  end

end
