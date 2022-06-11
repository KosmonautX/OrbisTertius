defmodule PhosWeb.OrbLive.FormComponent do
  use PhosWeb, :live_component

  alias PhosWeb.Util.Viewer
  alias Phos.Action

  @impl true
  def update(%{orb: orb} = assigns, socket) do
    changeset = Action.change_orb(orb)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", %{"orb" => orb_params}, socket) do
    changeset =
      socket.assigns.orb
      |> Action.change_orb(orb_params)
      |> Map.put(:action, :validate)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  # @impl true
  # def handle_event("location_update", %{"longitude" => longitude, "latitude" => latitude}, socket) do
  #   {:noreply, assign(socket, :live, %{longitude: longitude, latitude: latitude})}
  # end

  def handle_event("save", %{"orb" => orb_params}, socket) do
    generated_orb_id = Ecto.UUID.generate()
    # Process latlon value to x7 h3 indexes
    orb_params = try do
                     central_hash = socket.assigns.geolocation[String.to_existing_atom(orb_params["location"])][:geohash].hash
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
    orb_params = Map.put(orb_params, "id", generated_orb_id)

    file_uploaded =
    consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
      for res <- ["150x150", "1920x1080"] do
        {:ok, dest} = Phos.Orbject.S3.put("ORB", generated_orb_id, res)
        compressed_image =
          Mogrify.open(path)
          |> Mogrify.resize(res)
          |> Mogrify.save()
        HTTPoison.put(dest, {:file, compressed_image.path})
      end
      {:ok, path}
     end)

    unless Enum.empty?(file_uploaded) do
      orb_params = Map.put(orb_params, "media", true)
      save_orb(socket, socket.assigns.action, orb_params)
    else
      orb_params = Map.put(orb_params, "media", false)
      save_orb(socket, socket.assigns.action, orb_params)
    end


  end

  defp error_to_string(:too_large), do: "Image too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp save_orb(socket, :edit, orb_params) do
    case Action.update_orb(socket.assigns.orb, orb_params |> Viewer.update_orb_mapper()) do
      {:ok, orb} ->
        #orb_loc_publisher(orb, :mutation, orb_params["geolocation"])
        {:noreply,
         socket
         |> put_flash(:info, "Orb updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_orb(socket, :new, orb_params) do
    case Action.create_orb(orb_params) do
      {:ok, orb} ->
        orb_loc_publisher(orb, :genesis, orb_params["geolocation"])

        {:noreply,
         socket
         |> put_flash(:info, "Orb created successfully")
         |> push_redirect(to: socket.assigns.return_to)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

    end
  end

  defp orb_loc_publisher(orb, event, to_locations) do
    to_locations |> Enum.map(fn loc-> Phos.PubSub.publish(orb, {:orb, event}, loc_topic(loc)) end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"
end
