defmodule PhosWeb.CommentLive.ReplyComponent do
  use PhosWeb, :live_component

  alias Phos.Comments
  alias PhosWeb.Utility.Encoder

  @impl true
  def update(%{comment: comment} = assigns, socket) do
    changeset = Comments.change_comment(comment)

    {:ok,
     socket
     |> assign_new(:text, fn -> "" end)
     |> assign_new(:reply_comment, fn -> nil end)
     |> assign(assigns)
     |> assign(changeset: changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@changeset} phx-target={@myself} phx-submit="save">
        <div class="relative flex flex-col justify-center gap-2">
          <.error :for={msg <- Keyword.get_values(f.errors, :body)}><%= elem(msg, 0) %></.error>
          <textarea
            type="textarea"
            name="body"
            class="block w-full h-4 text-base text-gray-900 rounded-lg border border-gray-400"
            placeholder="In the beginning was the Word..."
          >
          </textarea>
          <button type="submit" class="absolute right-2.5 bottom-2.5">
            <Heroicons.paper_airplane class="h-8 w-8 mr-2 text-teal-400 font-bold" />
          </button>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("save", %{"body" => body}, socket) do
    comment_id = Ecto.UUID.generate()

    comment_params = %{
      "id" => comment_id,
      "path" => Encoder.encode_lpath(comment_id),
      "initiator_id" => socket.assigns.current_user.id,
      "orb_id" => socket.assigns.orb.id,
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
      "orb_id" => socket.assigns.orb.id,
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
