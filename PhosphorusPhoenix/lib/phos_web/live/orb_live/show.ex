defmodule PhosWeb.OrbLive.Show do
  use PhosWeb, :live_view

  alias Phos.Action
  alias Phos.Comments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do

    {:noreply,
     socket
     |> assign(:changeset, Comments.change_comment(%Comments.Comment{}))
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:orb, Action.get_orb!(id))
     |> assign(:comments, Comments.get_comments_by_orb(id))}
    #  |> assign(:image, {:ok, Phos.Orbject.S3.get("ORB", id, "150x150")})
  end

  @impl true
  def handle_event("save", %{"comment" => comment_params}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params =
      comment_params
      |> Map.put("id", comment_id)
      |> Map.put("path", hd(String.split(comment_id, "-")))

    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        # Add comment to socket assigns
        comment = comment |> Phos.Repo.preload([:initiator, :orb])
        updated_comments =
          [comment | socket.assigns.comments]
        {:noreply,
        socket
        |> assign(:comments, updated_comments)
        |> put_flash(:info, "Comment added successfully")}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Comments.get_comment!(id)

    updated_comments = Enum.reject(socket.assigns.comments, fn comment -> comment.id == id end)


    {:ok, _} = Comments.delete_comment(comment)

    {:noreply, socket
    |> assign(:comments, updated_comments)}
  end

  defp page_title(:show), do: "Show Orb"
  defp page_title(:edit), do: "Edit Orb"
end
