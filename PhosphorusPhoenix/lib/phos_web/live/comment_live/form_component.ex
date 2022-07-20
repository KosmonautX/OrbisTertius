defmodule PhosWeb.CommentLive.FormComponent do
  use PhosWeb, :live_component

  alias PhosWeb.Util.{Viewer,ImageHandler}
  alias Phos.Comments
  alias Phos.Action

  @impl true
  def update(assigns, socket) do
    changeset = Comments.change_comment(%Comments.Comment{})
    {:ok,
     socket
     |> assign(assigns)}
  end
end
