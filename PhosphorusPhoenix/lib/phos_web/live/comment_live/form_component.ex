defmodule PhosWeb.CommentLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Comments
  alias PhosWeb.Utility.Encoder
  import PhosWeb.SVG


  @impl true
  def update(assigns, socket) do
    IO.inspect(socket)
    {:ok,
      socket
      |> assign_new(:text, fn -> "" end)
      |> assign_new(:reply_comment, fn -> nil end)
      |> assign(assigns)
      |> assign_new(:changeset, fn -> Comments.change_comment(%Comments.Comment{}) end)}
  end

  @impl true
  def handle_event("new", %{"comment" => params}, socket) do
    comment_id = Ecto.UUID.generate()
    comment_params =
      params
      |> Map.put("id", comment_id)
      |> Map.put("path", Encoder.encode_lpath(comment_id))

    case Comments.create_comment_and_publish(comment_params) do
      {:ok, comment} ->
        send(self(), {:new_comment, comment})

        {:noreply,
        socket
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

    case Comments.create_comment_and_publish(comment_params) do
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
