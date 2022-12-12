defmodule PhosWeb.CommentLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Comments

  @impl true
  def update(assigns, socket) do
    changeset = Comments.change_comment(%Comments.Comment{})
    {:ok, socket |> assign(assigns) |> assign(changeset: changeset)}
  end
end
