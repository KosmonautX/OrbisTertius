defmodule PhosWeb.CommentLive.ReplyComponent do
  use PhosWeb, :live_component

  alias Phos.Comments
  alias PhosWeb.Utility.Encoder

  def update(assigns, socket) do
    changeset = Comments.change_comment(%Comments.Comment{})
    {:ok,
      socket
      |> assign_new(:text, fn -> "" end)
      |> assign_new(:reply_comment, fn -> nil end)
      |> assign(assigns)
      |> assign(changeset: changeset)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex p-2 gap-2 ml-2">
      <img
        src={Phos.Orbject.S3.get!("USR", Map.get(@current_user, :id), "public/profile/lossy")}
        class=" h-14 w-14 border-4 border-white rounded-full object-cover"
      />
      <div class="flex-1 relative">
        <input
          :if={@action == :edit and not is_nil(@comment)}
          class="block w-full p-4 text-base text-gray-900 focus:ring-black focus:outline-none  rounded-lg border border-gray-200 focus:ring-2 focus:ring-gray-200"
          placeholder={@action}
          required
          value="@comment.body"
        />
        <input
          :if={@action != :edit}
          class="block w-full p-4 text-base text-gray-900 focus:ring-black focus:outline-none  rounded-lg border border-gray-200 focus:ring-2 focus:ring-gray-200"
          placeholder={@action}
          required
        />
        <button type="submit" class="absolute right-2.5 bottom-2.5 ">
          <Heroicons.paper_airplane class="h-8 w-8 md:h-10 mr-2 text-teal-400 font-bold" />
        </button>
      </div>
    </div>
    """
  end

  def handle_event("new", %{"body" => body}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params = %{
      "id" => comment_id,
      "path" => Encoder.encode_lpath(comment_id),
      "initiator_id" => socket.assigns.current_user.id,
      "body" => body
    }

    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        send(self(), {:new_comment, comment})

        {:noreply,
        socket
        |> assign(changeset: %Comments.Comment{} |> Ecto.Changeset.change())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("reply", %{"parent_comment" => parent, "body" => body}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params = %{
      "id" => comment_id,
      "path" => Encoder.encode_lpath(comment_id, parent.path),
      "parent_id" => parent.id,
      "initiator_id" => socket.assigns.current_user.id,
      "body" => body
    }

    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        send(self(), {:child_comment, comment})

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("edit", %{"comment" => %{"comment_id" => comment_id, "body" => body}}, socket) do
    comment = Comments.get_comment!(comment_id)
    case Comments.update_comment(comment, %{body: body}) do
      {:ok, comment} ->
        send(self(), {:edit_comment, comment})

        {:noreply,
          socket
          |> assign(changeset: %Comments.Comment{} |> Ecto.Changeset.change())}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end


end
