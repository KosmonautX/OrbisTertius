defmodule PhosWeb.CommentLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Comments
  alias PhosWeb.Utility.Encoder

  @impl true
  def update(assigns, socket) do
    changeset = Comments.change_comment(%Comments.Comment{})
    {:ok,
      socket 
      |> assign_new(:text, fn -> "Add comment" end)
      |> assign_new(:reply_comment, fn -> nil end)
      |> assign(assigns) 
      |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("new", %{"comment" => params}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params =
      params
      |> Map.put("id", comment_id)
      |> Map.put("path", Encoder.encode_lpath(comment_id))

    case Comments.create_comment(comment_params) do
      {:ok, comment} -> 
        send(self(), {:new_comment, comment})

        {:noreply, 
        socket
        |> put_flash(:info, "Comment added successfully")
        |> assign(changeset: %Comments.Comment{} |> Ecto.Changeset.change())
      }
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("reply", %{"comment" => %{"parent_path" => parent_path} = params}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params =
      params
      |> Map.put("id", comment_id)
      |> Map.put("path", Encoder.encode_lpath(comment_id, parent_path))

    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        send(self(), {:new_comment, comment})

        {:noreply,
          socket
          |> put_flash(:info, "Reply added successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
