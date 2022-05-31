defmodule PhosWeb.OrbLive.FormComponent do
  use PhosWeb, :live_component

  alias Phos.Action

  @impl true
  def update(%{orb: orb} = assigns, socket) do
    changeset = Action.change_orb(orb)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
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
    # Process latlon value to x7 h3 indexes
    latlon = {socket.assigns.live.latitude, socket.assigns.live.longitude}
    |> :h3.from_geo(String.to_integer(orb_params["radius"]))
    |> :h3.k_ring(1)
    orb_params = Map.put(orb_params, "geolocation", latlon)

    save_orb(socket, socket.assigns.action, orb_params)
  end

  defp save_orb(socket, :edit, orb_params) do
    case Action.update_orb(socket.assigns.orb, orb_params) do
      {:ok, _orb} ->
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
      {:ok, _orb} ->
        {:noreply,
         socket
         |> put_flash(:info, "Orb created successfully")
         |> push_redirect(to: socket.assigns.return_to)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

    something -> IO.inspect something
    end
  end
end
