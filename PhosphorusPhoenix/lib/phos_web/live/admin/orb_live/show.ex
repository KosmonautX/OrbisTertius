defmodule PhosWeb.Admin.OrbLive.Show do
  use PhosWeb, :admin_view

  alias Phos.Action

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      allow_upload(socket, :image,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 8_888_888
      )

    case Action.get_orb(id) do
      {:ok, orb} ->
        {:ok, assign(socket, orb: orb, traits_form: orb.traits, changeset: Ecto.Changeset.change(orb))}

      _ ->
        raise PhosWeb.ErrorLive.FourOFour, message: "Orb Not Found Nomore"
    end
  end

  def update_title(resource, %{"orb" => %{"value" => title}}) do
    Action.update_orb(resource, %{title: title})
  end

  @impl true
  def handle_event("active", _params, %{assigns: %{orb: orb}} = socket) do
    case Action.update_orb(orb, %{active: !orb.active}) do
      {:ok, orb} ->
        {:noreply,
         socket
         |> assign(orb: orb)
         |> put_flash(:info, "Active Toggle Switched")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "orb status failed to update")}
    end
  end

  @impl true
  def handle_event("destroy", _params, %{assigns: %{orb: orb}} = socket) do
    case Action.delete_orb(orb) do
      {:ok, orb} ->
        {:noreply,
         socket
         |> put_flash(:info, "orb #{orb.title} is now dead 💀")
         |> push_redirect(to: ~p"/admin/orbs")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "orb status failed to update")}
    end
  end

  @impl true
  def handle_event(
        "trait_management",
        %{"method" => "delete", "id" => id} = _params,
        %{assigns: %{traits_form: val}} = socket
      ) do
    index = String.to_integer(id)
    {:noreply, assign(socket, traits_form: List.delete_at(val, index))}
  end

  @impl true
  def handle_event(
        "trait_management",
        %{"method" => "add"},
        %{assigns: %{traits_form: val}} = socket
      ) do
    {:noreply, assign(socket, traits_form: val ++ [""])}
  end

  @impl true
  def handle_event("trait_management", _params, socket) do
    {:noreply, assign(socket, traits_form: [""])}
  end

  @impl true
  def handle_event("trait_change", %{"orb" => trait_change} = _params, socket) do
    traits = Map.values(trait_change)
    {:noreply, assign(socket, :traits_form, traits)}
  end

  @impl true
  def handle_event(
        "save_trait",
        %{"orb" => trait_change} = _params,
        %{assigns: %{orb: orb}} = socket
      ) do
    traits = Map.values(trait_change)

    case Action.update_admin_orb(orb, %{traits: traits}) do
      {:ok, orb} ->
        {:noreply,
         socket
         |> assign(orb: orb, traits_form: orb.traits, changeset: Ecto.Changeset.change(orb))
         |> put_flash(:info, "orb traits updated.")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "orb traits failed to update")}
    end
  end

  @impl true
  def handle_event("change_image", _params, %{assigns: %{orb: orb}} = socket) do
    resolution = %{"150x150" => "public/banner/lossy", "1920x1080" => "public/banner/lossless"}

    file_uploaded =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        for res <- ["150x150", "1920x1080"] do
          {:ok, dest} = Phos.Orbject.S3.put("ORB", orb.id, resolution[res])

          compressed_image =
            path
            |> Mogrify.open()
            |> Mogrify.resize(res)
            |> Mogrify.save()

          HTTPoison.put(dest, {:file, compressed_image.path})
        end
        {:ok, path}
      end)

    if Enum.empty?(file_uploaded) do
      {:noreply, put_flash(socket, :error, "Error upload image")}
    else
      case Action.update_orb(orb, %{media: true}) do
        {:ok, orb} -> {:noreply, assign(socket, :orb, orb)}
        _ -> {:noreply, put_flash(socket, :error, "Error saving media")}
      end
    end
  end

  defp error_to_string(:too_large), do: "Image too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
