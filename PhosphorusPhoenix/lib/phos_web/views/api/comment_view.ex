defmodule PhosWeb.API.CommentView do
  use PhosWeb, :view
  alias PhosWeb.API.CommentView

  def render("index.json", %{comments: comments}) do
    %{data: render_many(comments, CommentView, "comment.json")}
  end

  def render("paginated.json", %{comments: comments}) do
    %{data: render_many(comments.data, CommentView, "comment.json"), meta: comments.meta}
  end

  def render("show.json", %{comment: comment}) do
    %{data: render_one(comment, CommentView, "comment.json")}
  end

  def render("comment.json", %{comment: comment}) do
    %{
      id: comment.id,
      active: comment.active,
      child_count: comment.child_count,
      body: comment.body,
      path: to_string(comment.path),
      parent_id: comment.parent_id,
      orb_id: comment.orb_id,
      relationships:  PhosWeb.Util.Viewer.relationship_mapper(comment)
    }
  end
end
