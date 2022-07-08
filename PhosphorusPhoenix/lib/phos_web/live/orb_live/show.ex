defmodule PhosWeb.OrbLive.Show do
  use PhosWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Phos.Action
  alias Phos.Comments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    {:noreply,
     socket
    |> assign(:changeset, Comments.change_comment(%Comments.Comment{}))
    |> assign(:orb, Action.get_orb!(id))
    |> assign(:comments, Comments.get_root_comments_by_orb(id))
    |> apply_action(socket.assigns.live_action, params)}
    #  |> assign(:image, {:ok, Phos.Orbject.S3.get("ORB", id, "150x150")})
  end

  defp apply_action(socket, :reply, %{"cid" => cid} = _params) do
    socket
    |> assign(:comment, Comments.get_comment!(cid))
    |> assign(:page_title, "Reply")
  end

  defp apply_action(socket, :show_ancestor, %{"id" => id, "cid" => cid} = _params) do
    comment = Comments.get_comment!(cid)
    IO.inspect(Comments.get_ancestor_comments_by_orb(id, to_string(comment.path)))
    socket
    |> assign(:comments, Comments.get_ancestor_comments_by_orb(id, to_string(comment.path)))
    |> assign(:page_title, "Show Ancestors")
  end

  defp apply_action(socket, :edit_comment, %{"cid" => cid} = _params) do
    socket
    |> assign(:comment, Comments.get_comment!(cid))
    |> assign(:page_title, "Edit")
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Show")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit")
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
        comment = comment |> Phos.Repo.preload([:initiator, :orb])
        # updated_comments =
        #   put_in(socket.assigns.comments, [String.split(to_string(comment.path), ".") |> List.to_tuple()], comment)
        comment = Map.put(comment, :has_child, !Enum.empty?(Comments.get_child_comments_by_orb(comment.orb_id, to_string(comment.path))))
        updated_comments =
          [{String.split(to_string(comment.path), ".") |> List.to_tuple(), comment} | socket.assigns.comments]
        {:noreply,
        socket
        |> assign(:comments, updated_comments)
        |> put_flash(:info, "Comment added successfully")}
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("reply", %{"comment" => comment_params}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params =
      comment_params
      |> Map.put("id", comment_id)
      |> Map.put("path", comment_params["parent_path"] <> "." <> hd(String.split(comment_id, "-")))

    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        comment = comment |> Phos.Repo.preload([:initiator, :orb])

        comment = Map.put(comment, :has_child, !Enum.empty?(Comments.get_child_comments_by_orb(comment.orb_id, to_string(comment.path))))
        updated_comments =
          [{String.split(to_string(comment.path), ".") |> List.to_tuple(), comment} | socket.assigns.comments]
        {:noreply,
        socket
        |> assign(:comments, updated_comments)
        |> put_flash(:info, "Reply added successfully")}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Comments.get_comment!(id)
    # updated_comments = Enum.reject(socket.assigns.comments, &elem(&1, 1).id == id)
    # updated_comments = Map.delete(socket.assigns.comments, String.split(to_string(comment.path), ".") |> List.to_tuple())

    # Instead of deleting comment, set comment active: false
    # {:ok, _} = Comments.delete_comment(comment)

    {:ok, comment} = Comments.update_comment(comment, %{active: false})
    # Instead of deleting comment, set comment active: false
    comment = Map.put(comment, :has_child, !Enum.empty?(Comments.get_child_comments_by_orb(comment.orb_id, to_string(comment.path))))
    updated_comment_index = Enum.find_index(socket.assigns.comments, fn c -> elem(c, 1).id == id end)
    updated_comments = List.replace_at(socket.assigns.comments, updated_comment_index, {String.split(to_string(comment.path), ".") |> List.to_tuple(), comment})

    {:noreply, socket
    |> assign(:comments, updated_comments)}
  end

  @impl true
  def handle_event("view_more", %{"orb" => orb_id, "path" => path}, socket) do
    comments = Comments.get_child_comments_by_orb(orb_id,path)

    updated_comments =
      comments ++ socket.assigns.comments

    {:noreply, socket
    |> assign(:comments, updated_comments)}
  end
end
