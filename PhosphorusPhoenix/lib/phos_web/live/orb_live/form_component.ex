defmodule PhosWeb.OrbLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Action

  @impl true
  def update(%{orb: orb} = assigns, socket) do
    changeset = Action.change_orb(orb)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .mp4 .gif .mov),
       max_entries: 5,
       max_file_size: 8_888_888
     )}
  end

  @impl true
  def handle_event("validate", %{"orb" => orb_params}, socket) do
    changeset =
      socket.assigns.orb
      |> Action.change_orb(orb_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"orb" => %{"location" => loc} = orb_params},
        %{assigns: %{addresses: addrs}} = socket
      ) do
    compression = %{"200x200" => "lossy", "1920x1080" => "lossless"}
    orb_id = socket.assigns.orb.id || Ecto.UUID.generate()
    # Process latlon value to x7 h3 indexes
    orb_params =
      try do
        central_hash =
          List.last(Map.get(addrs, String.to_existing_atom(loc), []))
          |> :h3.parent(String.to_integer(orb_params["radius"]))

        geohashes =
          central_hash
          |> :h3.k_ring(1)

        orb_params
        |> Map.put(
          "central_geohash",
          central_hash
        )
        |> Map.put("geolocation", geohashes)
      rescue
        ArgumentError -> orb_params |> Map.put("geolocation", [])
      end

    # Process image upload
    orb_params = Map.put(orb_params, "id", orb_id)

    file_uploaded =
      consume_uploaded_entries(socket, :image, fn %{path: path},
                                                  %{ref: count, client_type: type} ->
        case type |> String.split("/") |> hd() do
          "image" ->
            for {res, resolution} <- compression do
              {:ok, media} =
                Phos.Orbject.Structure.apply_media_changeset(%{
                  id: orb_id,
                  archetype: "ORB",
                  media: [
                    %{
                      access: "public",
                      essence: "banner",
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

          "video" ->
            ext = List.first(MIME.extensions(type))
            ext_path = "#{path}.#{ext}"
            File.rename!(path, ext_path)

            thumbnail = create_thumbnail(ext_path)

            {:ok, lossy_media} =
              Phos.Orbject.Structure.apply_media_changeset(%{
                id: orb_id,
                archetype: "ORB",
                media: [
                  %{
                    access: "public",
                    essence: "banner",
                    resolution: "lossy",
                    count: String.to_integer(count),
                    ext: "jpeg"
                  }
                ]
              })

            [lossy_dest | _] = Map.values(Phos.Orbject.S3.put_all!(lossy_media))

            HTTPoison.put(lossy_dest, {:file, thumbnail.path})

            {:ok, lossless_media} =
              Phos.Orbject.Structure.apply_media_changeset(%{
                id: orb_id,
                archetype: "ORB",
                media: [
                  %{
                    access: "public",
                    essence: "banner",
                    resolution: "lossless",
                    count: String.to_integer(count),
                    ext: ext
                  }
                ]
              })

            [lossless_dest | _] = Map.values(Phos.Orbject.S3.put_all!(lossless_media))

            HTTPoison.put(lossless_dest, {:file, ext_path})
        end

        {:ok, path}
      end)

    case Enum.empty?(file_uploaded) do
      false -> save_orb(socket, socket.assigns.action, Map.replace(orb_params, "media", true))
      _ -> save_orb(socket, socket.assigns.action, orb_params)
    end
  end

  defp create_thumbnail(ext_path) do
    ext_path
    |> Mogrify.open()
    |> Mogrify.format("jpeg")
    |> Map.update(:path, "", fn path -> path <> "[5]" end)
    |> Mogrify.save()
  end

  defp error_to_string(:too_large), do: "Image too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"


  defp save_orb(socket, :edit, orb_params) do
    case Action.update_orb(socket.assigns.orb, orb_params) do
      {:ok, orb} ->
        orb = orb |> Phos.Repo.preload([:initiator, :locations])
        location_list = orb.locations |> Enum.map(fn loc -> loc.id end)
        orb_loc_publisher(orb, :mutation, location_list)

        {:noreply,
         socket
         |> put_flash(:info, "Orb updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_orb(socket, :new, orb_params) do
    ## TODO swap with create orb with publish
    case Action.create_orb(orb_params) do
      {:ok, _orb} ->
        {:noreply,
         socket
         |> put_flash(:info, "Orb created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
    # case Action.create_orb_and_publish(orb_params) do
    #   {:ok, _orb} ->
    #     {:noreply,
    #      socket
    #      |> put_flash(:info, "Orb created successfully")
    #      |> push_redirect(to: socket.assigns.return_to)}

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     {:noreply, assign(socket, changeset: changeset)}
    # end
  end

  defp orb_loc_publisher(orb, event, to_locations) do
    to_locations
    |> Enum.map(fn loc ->
      Phos.PubSub.publish(%{orb | topic: loc}, {:orb, event}, loc_topic(loc))
    end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"
end
