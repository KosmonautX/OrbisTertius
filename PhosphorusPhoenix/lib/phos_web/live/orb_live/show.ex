defmodule PhosWeb.OrbLive.Show do
  use PhosWeb, :live_view

  alias Phos.Action
  alias Phos.Comments
  alias PhosWeb.Utility.Encoder

  @impl true
  def mount(
        %{"id" => id} = params,
        _session,
        %{assigns: %{current_user: %Phos.Users.User{} = user}} = socket
      ) do
    with %Action.Orb{} = orb <- Action.get_orb(id, user.id) do
      comments =
        Comments.get_root_comments_by_orb(orb.id)
        |> decode_to_comment_tuple_structure()

      Phos.PubSub.subscribe("folks")

      {:ok,
       socket
       |> assign(:orb, orb)
       |> assign_meta(orb, params)
       |> assign(:ally, false)
       |> assign(:media, nil)
       |> assign(:comments, comments)
       |> assign(:comment, %Comments.Comment{})
       |> assign(page: 1),
       temporary_assigns: [orbs: Action.orbs_by_initiators([orb.initiator.id], 1).data]}
      else
        nil -> raise PhosWeb.ErrorLive, message: "Orb Not Found"
    end
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    with {:ok, orb} <- Action.get_orb(id) do
      comment =
        Comments.get_root_comments_by_orb(orb.id)
        |> decode_to_comment_tuple_structure()

      {:ok,
       socket
       |> assign(:orb, orb)
       |> assign(:ally, false)
       |> assign_meta(orb, params)
       |> assign(:comments, comment)
       |> assign(:media, nil)
       |> assign(:comment, %Comments.Comment{})
       |> assign(page: 1),
       temporary_assigns: [orbs: Action.orbs_by_initiators([orb.initiator.id], 1).data]}
    else
      {:error, :not_found} -> raise PhosWeb.ErrorLive, message: "Orb Not Found"
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

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{topic: "folks", event: action, payload: root_id}, %{assigns: %{current_user: user}} = socket) when action in ["add", "reject", "accept"] do
    %{initiator_id: init_id, acceptor_id: acc_id} = root = Phos.Folk.get_relation!(root_id)
    case init_id == user.id or acc_id == user.id do
      true ->
        send_update(PhosWeb.Component.AllyButton, id: "user_information_card_ally", root_id: root.id)
        {:noreply, put_flash(socket, :info, "Relation updated")}
        _ -> {:noreply, put_flash(socket, :info, "no change on relation")}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{topic: "folks", event: "delete", payload: {init_id, acc_id}}, %{assigns: %{current_user: user}} = socket) do
    case init_id == user.id or acc_id == user.id do
      true -> 
        send_update(PhosWeb.Component.AllyButton, id: "user_information_card_ally", related_users: %{receiver_id: init_id, sender_id: user.id})
        {:noreply, put_flash(socket, :error, "Ally request is deleted") }
        _ -> {:noreply, put_flash(socket, :info, "handle info not matched")}
    end
  end

  defp apply_action(socket, :reply, %{"id" => _orb_id, "cid" => cid} = _params) do
    socket
    |> assign(:comment, Comments.get_comment!(cid))
    |> assign(:page_title, "Replying")
  end

  defp apply_action(socket, :show_ancestor, %{"id" => orb_id, "cid" => cid} = _params) do
    comment = Comments.get_comment!(cid)

    socket
    |> assign(
      :comments,
      Comments.get_ancestor_comments_by_orb(orb_id, to_string(comment.path))
      |> decode_to_comment_tuple_structure()
    )
    |> assign(:page_title, "Show Ancestors")
  end

  defp apply_action(socket, :edit_comment, %{"cid" => cid} = _params) do
    socket
    |> assign(:comment, Comments.get_comment!(cid))
    |> assign(:page_title, "Editing Comments")
  end

    defp apply_action(socket, :show, %{"id" => id, "media" => media}) do
    socket
    |> assign(:page_title, "")
    |> assign(:media, Phos.Orbject.S3.get!("ORB", id, media))
  end


  defp apply_action(socket, :show, %{"id" => _id}) do
    socket
    |> assign(:page_title, "")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Editing")
  end

  defp assign_meta(socket, orb, %{"bac" => _}), do: socket |> assign(:redirect, true) |> assign_meta(orb)
  defp assign_meta(socket, orb, _), do: assign_meta(socket, orb)
  defp assign_meta(socket, orb) do
    media = Phos.Orbject.S3.get_all!("ORB", orb.id, "public/banner/lossless")
        |> (fn media ->
        (for {path, url} <- media || [] do
        %Phos.Orbject.Structure.Media{
        ext: MIME.from_path(path) |> String.split("/") |> hd,
        url: url,
        mimetype: MIME.from_path(path)
        } end) end).()
        |> List.first()

    assign(socket, :meta, %{
      author: orb.initiator,
      mobile_redirect: "orbland/orbs/" <> orb.id,
      title: " #{orb.title} by #{orb.initiator.username}",
      description:
        "#{get_in(orb, [Access.key(:payload, %{}), Access.key(:info, "")])} #{orb |> get_in([Access.key(:payload, %{}), Access.key(:inner_title, "-")])}",
      type: "website",
      image: (if (!is_nil(media) && media.ext in ["application", "image"]), do: media.url),
      video: (if (!is_nil(media) && media.ext in ["video"]), do: media.url),
      "video:type": (if (!is_nil(media) && media.ext in ["video"]), do: media.mimetype),
      url: url(socket, ~p"/orb/#{orb}")
    })
  end


  def handle_event("load-more", _, %{assigns: %{page: page, orb: orb}} = socket) do
    expected_page = page + 1
    case Action.orbs_by_initiators([orb.initiator.id], expected_page).data do
      [_|_] = orbs -> {:noreply, assign(socket, page: expected_page, orbs: orbs)}
      _ -> {:noreply, socket}
    end
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
        updated_comments = [
          {String.split(to_string(comment.path), ".") |> List.to_tuple(), comment}
          | socket.assigns.comments
        ]

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
    updated_comment_index =
      Enum.find_index(socket.assigns.comments, fn c -> elem(c, 1).id == id end)

    updated_comments =
      List.replace_at(
        socket.assigns.comments,
        updated_comment_index,
        {String.split(to_string(comment.path), ".") |> List.to_tuple(), comment}
      )

    # TODO: To populate child_count
    {:noreply,
     socket
     |> assign(:comments, updated_comments)}
  end

  @impl true
  def handle_event(
        "toggle_more_replies",
        %{"initmorecomments" => initmorecomments, "orb" => orb_id, "path" => path},
        socket
      ) do
    updated_comments =
      if initmorecomments == "true" do
        comments =
          Comments.get_child_comments_by_orb(orb_id, path) |> decode_to_comment_tuple_structure()

        socket.assigns.comments ++ comments
      else
        socket.assigns.comments
      end

    {:noreply,
     socket
     |> assign(:comments, updated_comments)}
  end

  defp save_comment(socket, :reply, comment_params) do
    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        comment = comment |> Phos.Repo.preload([:initiator, :orb])

        # comment = Map.put(comment, :has_child, !Enum.empty?(Comments.get_child_comments_by_orb(comment.orb_id, to_string(comment.path))))
        updated_comments = [
          {String.split(to_string(comment.path), ".") |> List.to_tuple(), comment}
          | socket.assigns.comments
        ]

        {:noreply,
         socket
         |> assign(:comments, updated_comments)
         |> put_flash(:info, "Reply added successfully")
         |> push_patch(to: ~p"/orb/#{comment.orb_id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def decode_to_comment_tuple_structure(comments) do
    for c <- comments, into: [] do
      {String.split(to_string(c.path), ".") |> List.to_tuple(), c}
    end
  end
end
