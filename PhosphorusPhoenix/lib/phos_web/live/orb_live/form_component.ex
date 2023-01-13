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
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, max_file_size: 8888888)}
  end

  @impl true
  def handle_event("validate", %{"orb" => orb_params}, socket) do
    changeset =
      socket.assigns.orb
      |> Action.change_orb(orb_params)
      |> Map.put(:action, :validate)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"orb" => orb_params}, socket) do
    resolution = %{"150x150" => "lossy", "1920x1080" => "lossless"}
    orb_id = socket.assigns.orb.id || Ecto.UUID.generate()
    # Process latlon value to x7 h3 indexes
    orb_params = try do
                     central_hash = List.last(socket.assigns.addresses[String.to_atom(orb_params["location"])])
                     |> :h3.parent(String.to_integer(orb_params["radius"]))
                     geohashes = central_hash
                     |> :h3.k_ring(1)
                     orb_params
                     |> Map.put("central_geohash", central_hash)
                     |> Map.put("geolocation", geohashes)
                   rescue
                     ArgumentError -> orb_params |> Map.put("geolocation", [])
                   end

    # Process image upload
    orb_params = Map.put(orb_params, "id", orb_id)

    file_uploaded =
    consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
      for res <- ["150x150", "1920x1080"] do
        {:ok, dest} = Phos.Orbject.S3.put("ORB", orb_id, "public/banner/#{resolution[res]}")
        compressed_image =path
        |> Mogrify.open()
        |> Mogrify.resize(res)
        |> Mogrify.save()

        HTTPoison.put(dest, {:file, compressed_image.path})
      end
      {:ok, path}
     end)

    if Enum.empty?(file_uploaded) and orb_params["media"] == "false" do
      save_orb(socket, socket.assigns.action, orb_params)
    else
      orb_params = Map.replace(orb_params, "media", true)
      save_orb(socket, socket.assigns.action, orb_params)
    end


  end

  defp error_to_string(:too_large), do: "Image too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

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
    case Action.create_orb_and_publish(orb_params) do
      {:ok, _orb} ->
        {:noreply,
         socket
         |> put_flash(:info, "Orb created successfully")
         |> push_redirect(to: socket.assigns.return_to)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

    end
  end

  defp orb_loc_publisher(orb, event, to_locations) do
    to_locations |> Enum.map(fn loc-> Phos.PubSub.publish(%{orb | topic: loc}, {:orb, event}, loc_topic(loc)) end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"
end
