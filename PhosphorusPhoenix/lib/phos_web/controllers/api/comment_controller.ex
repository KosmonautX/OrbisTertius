defmodule PhosWeb.API.CommentController do
  use PhosWeb, :controller

  alias Phos.Comments
  alias Phos.Comments.Comment
  alias PhosWeb.Utility.Encoder

  action_fallback PhosWeb.API.FallbackController

  # curl -H "Content-Type: application/json" -H "Authorization:$(curl -X GET 'http://localhost:4000/api/devland/flameon?user_id=d9476604-f725-4068-9852-1be66a046efd' | jq -r '.payload')" -X GET 'http://localhost:4000/api/comments'

  def index(conn = %{assigns: %{current_user: %{id: user_id}}}, _params) do
    comments = Comments.list_comments_by_initiator(user_id)
    render(conn, :index, comments: comments)
  end
  # curl -H "Content-Type: application/json" -X GET http://localhost:4000/api/comments


  def create(conn = %{assigns: %{current_user: %{id: user_id}}}, comment_params) do
    comment_params = case comment_params do
      # Create child comment flow
      %{"parent_id" => parent_id} ->
        parent_comment = Comments.get_comment!(parent_id)
        comment_id = Ecto.UUID.generate()
        %{"id" => comment_id,
                           "orb_id" => parent_comment.orb_id,
                           "parent_id" => parent_comment.id,
                           "initiator_id" => user_id,
                           "path" => Encoder.encode_lpath(comment_id, to_string(parent_comment.path)),
                           "body" => comment_params["body"]}

      # Create root comment flow
      %{"orb_id" => orb_id} ->
        comment_id = Ecto.UUID.generate()
        %{"id" => comment_id,
                           "orb_id" => orb_id,
                           "initiator_id" => user_id,
                           "path" => Encoder.encode_lpath(comment_id),
                           "body" => comment_params["body"]}
    end

    with {:ok, %Comment{} = comment} <- Comments.create_comment_and_publish(comment_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location",  ~p"/api/orbland/comments/#{comment.id}")
          |> render(:show, comment: comment)
    end
  end

  def show(conn, %{"id" => id}) do
    comment = Comments.get_comment!(id)
    render(conn, :show, comment: comment)
  end

  # curl -H "Content-Type: application/json" -X POST -d '{"comment": {"id": "51f7a029-2023-4da1-8ff8-7981ac81b7a8", "body": "Hi comment", "path": "51f7a029", "active": "true", "orb_id": "a003b89a-74a5-448a-9b7a-94a4e2324cb3", "initiator_id": "d9476604-f725-4068-9852-1be66a046efd"}}' http://localhost:4000/api/comments

  def show_children(conn, %{"id" => id, "page" => page}) do
      comments = Comments.get_descendents_comment(id, page)
      render(conn, :paginated, comments: comments)
  end

  def show_children(conn, %{"id" => id}) do
      comments = Comments.get_descendents_comment(id, 1)
      render(conn, :paginated, comments: comments)
  end
  # curl -H "Content-Type: application/json" -X GET http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b

  def show_root(conn, %{"id" => id, "page" => page}) do
    comments = Comments.get_root_comments_by_orb(id, page)
    render(conn, :paginated, comments: comments)
  end

  def show_root(conn, %{"id" => id}) do
    comments = Comments.get_root_comments_by_orb(id)
    render(conn, :index, comments: comments)
  end
  # curl -H "Content-Type: application/json" -X GET http://localhost:4000/api/orbs/aa3609f6-a988-44c2-b9fa-67d8729639f7/root

  def show_ancestor(conn, %{"id" => id}) do
    comment = Comments.get_comment!(id)
    comments = Comments.get_ancestor_comments_by_orb(comment.orb_id, to_string(comment.path))
    render(conn, :index, comments: comments)
  end

  def update(conn = %{assigns: %{current_user: user}}, %{"id" => id} = comment_params) do
    comment = Comments.get_comment!(id)

    with true <- comment.initiator.id == user.id,
         {:ok, %Comment{} = comment} <- Comments.update_comment(comment, comment_params) do
      render(conn, :show, comment: comment)
    else
      false -> {:error, :unauthorized}
      error -> error
    end
  end
  # curl -H "Content-Type: application/json" -X PUT -d '{"comment": {"active": "false"}}' http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b
  # curl -H "Content-Type: application/json" -X PUT -d '{"comment": {"body": "HENLOO!"}}' http://localhost:4000/api/comments/a7bb9551-4561-4bf0-915a-263168bbcc9b

  def delete(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
    comment = Comments.get_comment!(id)

    with true <- comment.initiator.id == user.id,
         {:ok, %Comment{}} <- Comments.delete_comment(comment) do
      send_resp(conn, :no_content, "")
      else
      false -> {:error, :unauthorized}
      error -> error
    end
  end
end
