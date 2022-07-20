defmodule PhosWeb.UserProfileLive.FormComponent do
  use PhosWeb, :live_component

  alias PhosWeb.Util.{Viewer,ImageHandler}
  alias Phos.Users
  alias Phos.Users.{User}

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Users.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, max_file_size: 8888888)}
  end

  @impl true
  def handle_event("validate", %{"user" => profile_params}, socket) do
    changeset =
      socket.assigns.user
      |> Users.change_user(profile_params)
      |> Map.put(:action, :validate)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => profile_params}, socket) do
    # Process image upload
    file_uploaded =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        for res <- ["150x150", "1920x1080"] do
          {:ok, dest} = Phos.Orbject.S3.put("USR", profile_params["user_id"], res)
          #compressed_image_path = ImageHandler.resize_file(path, res, Path.extname(entry.client_name))
          compressed_image =path
          |> Mogrify.open()
          #|> Mogrify.gravity("Center")
          |> Mogrify.resize(res)
          |> Mogrify.save()

          HTTPoison.put(dest, {:file, compressed_image.path})
        end
        {:ok, path}
       end)

    if Enum.empty?(file_uploaded) and profile_params["media"] == "false" do
      save_profile(socket, socket.assigns.action, profile_params)
    else
      profile_params = Map.replace(profile_params, "media", true)
      save_profile(socket, socket.assigns.action, profile_params)
    end
  end

  defp error_to_string(:too_large), do: "Image too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp save_profile(socket, :edit, profile_params) do
    case Users.update_user(socket.assigns.user, profile_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
