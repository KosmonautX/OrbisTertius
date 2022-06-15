defmodule PhosWeb.OrbLive.MapComponent do
  use PhosWeb, :live_component

  alias PhosWeb.Util.{Viewer,ImageHandler}
  alias Phos.Action

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
      |> assign(assigns)
      |> assign(:markerloc,  %{latitude: 1.3521, longitude: 103.8198})}
  end

  @impl true
  def handle_event("modalmap_setloc", %{"lng" => longitude, "lat" => latitude}, socket) do
    {:noreply, socket
      |> assign(:markerloc, %{latitude: latitude, longitude: longitude})}
  end

  @impl true
  def handle_event("save_loc", %{"lng" => longitude, "lat" => latitude}, socket) do
    {_, updated_geolocation} = get_and_update_in(socket.assigns.geolocation, Enum.map([socket.assigns.setloc, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.from_geo({String.to_float(latitude), String.to_float(longitude)}, 10), radius: 10}})
    # Geosub here?
    send(self(), {:locnameupdated, updated_geolocation})
    # Ecto update user loc
    {:noreply, socket
      |> put_flash(:info, "#{String.capitalize(to_string(socket.assigns.setloc))} location saved")
      |> push_patch(to: socket.assigns.return_to)}
  end
end
