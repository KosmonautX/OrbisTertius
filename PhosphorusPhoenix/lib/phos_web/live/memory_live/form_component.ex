defmodule PhosWeb.MemoryLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Message
  import PhosWeb.SVG

  @impl true
  def update(%{memory: memory} = assigns, socket) do
    changeset = Message.change_memory(memory)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(changeset: changeset)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png ),
       max_entries: 5,
       max_file_size: 8_888_888
     )}
  end

  @impl true
  def handle_event("validate", %{"memory" => memory_params}, socket) do
    changeset =
      socket.assigns.memory
      |> Message.change_memory(memory_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end


  def handle_event("save", %{"memory" => memory_params}, socket) do
    compression = %{"200x200" => "lossy", "1920x1080" => "lossless"}
    memory_id = socket.assigns.memory.id || Ecto.UUID.generate()

    memory_params = Map.put(memory_params, "id", memory_id)
    file_uploaded =
      consume_uploaded_entries(socket, :image, fn %{path: path},
                                                  %{ref: count, client_type: type} ->
        case type |> String.split("/") |> hd() do
          "image" ->
            for {res, resolution} <- compression do
              {:ok, media} =
                Phos.Orbject.Structure.apply_media_changeset(%{
                  id: memory_id,
                  archetype: "MEM",
                  media: [
                    %{
                      access: "public",
                      essence: "profile",
                      resolution: resolution,
                      count: String.to_integer(count),
                      ext: List.first(MIME.extensions(type))
                    }
                  ]
                })

              [dest | _] = Map.values(Phos.Orbject.S3.put_all!(media))

              compressed_image =
                path
                |> Mogrify.open()
                |> Mogrify.resize(res)
                |> Mogrify.save()

              HTTPoison.put(dest, {:file, compressed_image.path})
            end
        end
        {:ok, path}
      end)

    memory_params =
      unless Enum.empty?(file_uploaded) do
        Map.replace(memory_params, "media", true)
      else
        memory_params
      end

    save_memory(socket, socket.assigns.action, memory_params)
  end

  defp save_memory(socket, :edit, memory_params) do
    case Message.update_memory(socket.assigns.memory, memory_params) do
      {:ok, _memory} ->
        {:noreply,
         socket
         |> put_flash(:info, "Memory updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_memory(%{assigns: %{rel: relation, current_user: user}} = socket, :new, params) do
    with user_destination <- get_receiver_id(relation, user),
         memory_params <- Map.merge(params, %{"id" => Ecto.UUID.generate(), "user_destination_id" => user_destination}),
         {:ok, _memory} <- Message.create_message(memory_params) do
           {:noreply,
             socket
             |> put_flash(:info, "Memory created successfully")
             |> push_navigate(to: socket.assigns.navigate)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp get_receiver_id(%{acceptor_id: acc_id} = rel, %{id: id} = _user) when acc_id == id,
    do: rel.initiator_id

  defp get_receiver_id(%{acceptor_id: id} = _rel, _user), do: id

  defp get_receiver_id(id, user) when is_binary(id) do
    id
    |> Phos.Folk.get_relation!()
    |> get_receiver_id(user)
  end

  defp error_to_string(:too_large), do: "Image too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

end
