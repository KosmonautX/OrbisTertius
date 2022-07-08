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


  # @impl true
  # def handle_event("save", %{"comment" => comment_params}, socket) do
  #   comment_id = Ecto.UUID.generate()
  #   comment_params =
  #     comment_params
  #     |> Map.put("id", comment_id)
  #     |> Map.put("path", hd(String.split(comment_id, "-")))

  #   case Comments.create_comment(comment_params) do
  #     {:ok, comment} ->
  #       comment = comment |> Phos.Repo.preload([:initiator, :orb])
  #       updated_comments =
  #         put_in(socket.assigns.comments, [String.split(to_string(comment.path), ".") |> List.to_tuple()], comment)
  #       {:noreply,
  #       socket
  #       |> assign(:comments, updated_comments)
  #       |> put_flash(:info, "Comment added successfully")}
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       IO.inspect(changeset)
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end

  # @impl true
  # def handle_event("reply", %{"comment" => comment_params}, socket) do
  #   comment_id = Ecto.UUID.generate()
  #   IO.inspect(comment_params)
  #   comment_params =
  #     comment_params
  #     |> Map.put("id", comment_id)
  #     |> Map.put("path", comment_params["parent_path"] <> "." <> hd(String.split(comment_id, "-")))

  #   case Comments.create_comment(comment_params) do
  #     {:ok, comment} ->
  #       # TODO: Comment structure
  #       comment = comment |> Phos.Repo.preload([:initiator, :orb])
  #       updated_comments =
  #         [comment | socket.assigns.comments]
  #       {:noreply,
  #       socket
  #       |> assign(:comments, updated_comments)
  #       |> put_flash(:info, "Reply added successfully")}
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end

  # @impl true
  # def handle_event("delete", %{"id" => id}, socket) do
  #   comment = Comments.get_comment!(id)

  #   # updated_comments = Enum.reject(socket.assigns.comments, fn comment -> comment.id == id end)
  #   updated_comments = Map.delete(socket.assigns.comments, String.split(to_string(comment.path), ".") |> List.to_tuple())


  #   {:ok, _} = Comments.delete_comment(comment)

  #   {:noreply, socket
  #   |> assign(:comments, updated_comments)}
  # end

  # @impl true
  # def handle_event("view_more", %{"orb" => orb_id, "path" => path}, socket) do
  #   comments = Comments.get_child_comments_by_orb(orb_id,path)

  #   {:noreply, socket
  #   |> assign(:comments, comments)}
  # end

  # def show_nested_comments(assigns) do
  #   ~H"""
  #     <%= for c <- assigns.comments do %>
  #       <!-- Comment Threaded Variation -->
  #     <div class="comments">
  #       <div class="comment">
  #           <a class="avatar">
  #               <img src={ Phos.Orbject.S3.get!("USR", @current_user.id, "150x150") }>
  #           </a>
  #           <div class="content">
  #               <a class="author">
  #                 <%= c.initiator_id %>
  #               </a>
  #               <div class="metadata">
  #                   <span class="date">Just now</span>
  #               </div>
  #               <div class="text">
  #                 <%= c.body %>
  #               </div>
  #               <div class="actions">
  #                   <a class="reply">Reply</a>
  #               </div>
  #           </div>
  #       </div>
  #     </div>
  #     <% end %>
  #   """
  # end
end
