defmodule PhosWeb.CommentLive.ShowComponent do
  use PhosWeb, :live_component

  import Phos.Comments, only: [filter_child_comments_chrono: 2]

  def mount(socket), do: {:ok, socket}

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(:orb, assigns.orb)
      |> assign(:comment, assigns.comment)
      |> assign(:comments, assigns.comments)
      |> assign(:current_user, assigns.current_user)
      |> assign(:changeset, assigns.changeset)
      |> assign_new(:edit_comment, fn -> nil end)
      |> assign_new(:reply_comment, fn -> nil end)}
  end

  def handle_event("reply-comment", %{"comment-id" => id}, socket) do
    {:noreply, assign(socket, reply_comment: id, edit_comment: nil)}
  end

  def handle_event("cancel-reply", _, socket) do
    {:noreply, assign(socket, reply_comment: nil)}
  end

  def handle_event("edit-comment", %{"comment-id" => id}, socket) do
    {:noreply, assign(socket, edit_comment: id, reply_comment: nil)}
  end

  def handle_event("cancel-edit", _, socket) do
    {:noreply, assign(socket, edit_comment: nil)}
  end
end
