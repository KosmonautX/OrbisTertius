defmodule PhosWeb.OrbLive.MapComponent do
  use PhosWeb, :live_component

  alias PhosWeb.Util.{Viewer,ImageHandler}
  alias Phos.Action
  alias Phos.Users

  @impl true
  def update(assigns, socket) do
    # If user has old ":home, :work" geolocation, set the lat and lng to :markerloc else, use default
    {lat, lng} =
      if assigns[:geolocation][assigns[:setloc]] do
        assigns[:geolocation][assigns[:setloc]][:geohash][:hash]
          |> :h3.to_geo()
      else
        {1.3521, 103.8198}
      end
    {:ok,
     socket
      |> assign(assigns)
      |> assign(:markerloc,  %{latitude: lat, longitude: lng})
      |> push_event("add_old_marker", %{latitude: lat, longitude: lng})}
  end

  @impl true
  @spec handle_event(<<_::64, _::_*56>>, map, map) :: {:noreply, map}
  def handle_event("modalmap_setloc", %{"lng" => longitude, "lat" => latitude}, socket) do
    {:noreply, socket
      |> assign(:markerloc, %{latitude: latitude, longitude: longitude})}
  end

  @impl true
  def handle_event("save_loc", %{"lng" => longitude, "lat" => latitude}, socket) do
    user = Users.get_pte_profile_by_fyr(socket.assigns.user_id)

    priv_profile_loc = Enum.filter(user.private_profile.geolocation, fn u -> u.id == to_string(socket.assigns.setloc) end) |> List.first()

    flash_msg =
      # Unless to change
      unless priv_profile_loc == nil do
        if DateTime.utc_now() |> DateTime.to_unix() < priv_profile_loc.chronolock do
          "not yet 14 days"
        else

          # pte_profile = Phos.Repo.get!(Users.Private_Profile, "31ab99bb-f2ff-4683-8cdf-485ceb76115f")
          # Update Ecto

          # Generate a changeset
          # changeset = Ecto.Changeset.change(pte_profile)

          # selected_loc = List.first(pte_profile.geolocation)

          # Put embeds into changeset
          # updated_geo = Ecto.Changeset.change(selected_loc, %{id: to_string(socket.assigns.setloc), geohash: :h3.from_geo({String.to_float(latitude), String.to_float(longitude)}, 10), chronolock: DateTime.utc_now() |> DateTime.add(14 * 3600 * 24, :second) |> DateTime.to_unix(), location_description: nil})
          # Ecto.Changeset.put_embed(changeset, :geolocation, [updated_geo])
          # |> IO.inspect()

          send(self(), {:static_location_update, %{"locname" => socket.assigns.setloc ,"longitude" => String.to_float(longitude), "latitude" => String.to_float(latitude)}})
          "#{String.capitalize(to_string(socket.assigns.setloc))} location saved"
        end
      end

    {:noreply, socket
        |> put_flash(:info, flash_msg)
        |> push_patch(to: socket.assigns.return_to)}
  end
end
