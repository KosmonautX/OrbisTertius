defmodule PhosWeb.API.CommentView do
  use PhosWeb, :view
  alias PhosWeb.API.CommentView

  def render("index.json", %{comments: comments}) do
    %{data: render_many(comments, CommentView, "comment.json")}
  end

  def render("show.json", %{comment: comment}) do
    %{data: render_one(comment, CommentView, "comment.json")}
  end

  def render("comment.json", %{comment: comment}) do
    %{
      id: comment.id,
      active: comment.active,
      body: comment.body,
      path: to_string(comment.path),
      parent_id: comment.parent_id,
      orb_id: comment.orb_id
    }
  end
end
