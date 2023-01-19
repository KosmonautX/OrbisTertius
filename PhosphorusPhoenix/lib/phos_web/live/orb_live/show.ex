defmodule PhosWeb.OrbLive.Show do
  use PhosWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Phos.Action
  alias Phos.Comments
  alias PhosWeb.Utility.Encoder

  @impl true
  def mount(%{"id" => id} = _params, _session, socket = %{assigns: %{current_user: user}}) do
    with %Action.Orb{} = orb <-  Action.get_orb(id, user.id) do
      orb = orb
            |> put_in([Access.key(:initiator), Access.key(:locations)], ["Singapore", "Vandavasi"])
            |> put_in([Access.key(:initiator), Access.key(:traits)], ["frontend", "200wpm"])

      comment = Comments.get_root_comments_by_orb(orb.id)
      |> decode_to_comment_tuple_structure()

      {:ok, socket
      |> assign(:orb, orb)
      |> assign(:comments, comment)}
    end
  end

  @impl true
  def handle_params(params, _, socket) do

    {:noreply,
     socket
    |> assign(:changeset, Comments.change_comment(%Comments.Comment{}))
    |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:new_comment, %{orb_id: orb_id}}, socket) do
    comments = Comments.get_root_comments_by_orb(orb_id) |> decode_to_comment_tuple_structure()
    {:noreply, 
      assign(socket, :comments, comments) 
      |> put_flash(:info, "Comment added successfully")}
  end

  @impl true
  def handle_info({:child_comment, %{orb_id: orb_id}}, socket) do
    comments = Comments.get_root_comments_by_orb(orb_id) |> decode_to_comment_tuple_structure()
    {:noreply, 
      assign(socket, :comments, comments) 
      |> put_flash(:info, "Reply added successfully")}
  end

  @impl true
  def handle_info({:edit_comment, %{orb_id: orb_id}}, socket) do
    comments = Comments.get_root_comments_by_orb(orb_id) |> decode_to_comment_tuple_structure()
    {:noreply, 
      assign(socket, comments: comments, edit_comment: nil) 
      |> put_flash(:info, "Comment updated successfully")}
  end

  defp apply_action(socket, :reply, %{"id" => _orb_id, "cid" => cid} = _params) do
    socket
    |> assign(:comment, Comments.get_comment!(cid))
    |> assign(:page_title, "Reply")

  end

  defp apply_action(socket, :show_ancestor, %{"id" => orb_id, "cid" => cid} = _params) do
    comment = Comments.get_comment!(cid)
    socket
    |> assign(:comments, Comments.get_ancestor_comments_by_orb(orb_id, to_string(comment.path)) |> decode_to_comment_tuple_structure())
    |> assign(:page_title, "Show Ancestors")
  end

  defp apply_action(socket, :edit_comment, %{"cid" => cid} = _params) do
    socket
    |> assign(:comment, Comments.get_comment!(cid))
    |> assign(:page_title, "Edit")
  end

  defp apply_action(socket, :show, %{"id" => _id} = _params) do
    socket
    |> assign(:page_title, "Show")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit")
  end

  # Save comment flow
  @impl true
  def handle_event("save", %{"comment" => comment_params}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params =
      comment_params
      |> Map.put("id", comment_id)
      |> Map.put("path", Encoder.encode_lpath(comment_id))

    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        comment = comment |> Phos.Repo.preload([:initiator, :orb])
        # updated_comments =
        #   put_in(socket.assigns.comments, [String.split(to_string(comment.path), ".") |> List.to_tuple()], comment)
        # comment = Map.put(comment, :has_child, !Enum.empty?(Comments.get_child_comments_by_orb(comment.orb_id, to_string(comment.path))))
        updated_comments =
          [{String.split(to_string(comment.path), ".") |> List.to_tuple(), comment} | socket.assigns.comments]
        {:noreply,
        socket
        |> assign(:comments, updated_comments)
        |> put_flash(:info, "Comment added successfully")
        |> push_patch(to: ~p"/orb/#{comment.orb_id}")}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # Reply comment flow
  @impl true
  def handle_event("reply", %{"comment" => comment_params}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params =
      comment_params
      |> Map.put("id", comment_id)
      |> Map.put("path", Encoder.encode_lpath(comment_id, comment_params["parent_path"]))

    # save_comment(socket, :reply, comment_params)
    save_comment(socket, socket.assigns.live_action, comment_params)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Comments.get_comment!(id)
    {:ok, comment} = Comments.update_comment(comment, %{active: false})
    # comment = Map.put(comment, :has_child, !Enum.empty?(Comments.get_child_comments_by_orb(comment.orb_id, to_string(comment.path))))
    updated_comment_index = Enum.find_index(socket.assigns.comments, fn c -> elem(c, 1).id == id end)
    updated_comments = List.replace_at(socket.assigns.comments, updated_comment_index, {String.split(to_string(comment.path), ".") |> List.to_tuple(), comment})
    # TODO: To populate child_count
    {:noreply, socket
    |> assign(:comments, updated_comments)}
  end

  @impl true
  def handle_event("toggle_more_replies", %{"initmorecomments" => initmorecomments, "orb" => orb_id, "path" => path}, socket) do
    updated_comments =
      if initmorecomments == "true" do
        comments = Comments.get_child_comments_by_orb(orb_id,path) |> decode_to_comment_tuple_structure()
        socket.assigns.comments ++ comments
      else
        socket.assigns.comments
      end

    {:noreply, socket
    |> assign(:comments, updated_comments)}
  end


  defp save_comment(socket, :reply, comment_params) do
    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        comment = comment |> Phos.Repo.preload([:initiator, :orb])

        # comment = Map.put(comment, :has_child, !Enum.empty?(Comments.get_child_comments_by_orb(comment.orb_id, to_string(comment.path))))
        updated_comments =
          [{String.split(to_string(comment.path), ".") |> List.to_tuple(), comment} | socket.assigns.comments]

        {:noreply,
        socket
        |> assign(:comments, updated_comments)
        |> put_flash(:info, "Reply added successfully")
        |> push_patch(to: ~p"/orb/#{comment.orb_id}")}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_comment(socket, :edit_comment, comment_params) do
    case Comments.update_comment(socket.assigns.comment, %{body: comment_params["body"]}) do
      {:ok, comment} ->
        comment = comment |> Phos.Repo.preload([:initiator, :orb])
        updated_comment_index = Enum.find_index(socket.assigns.comments, fn c -> elem(c, 1).id == socket.assigns.comment.id end)
        updated_comments = List.replace_at(socket.assigns.comments, updated_comment_index, {String.split(to_string(comment.path), ".") |> List.to_tuple(), comment})

        {:noreply,
         socket
         |> put_flash(:info, "Comment updated successfully")
         |> push_patch(to: ~p"/orb/#{comment.orb_id}")
         |> assign(:comments, updated_comments)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def decode_to_comment_tuple_structure(comments) do
    for c <- comments, into: [] do
      {String.split(to_string(c.path), ".") |> List.to_tuple(), c}
    end
  end
end
