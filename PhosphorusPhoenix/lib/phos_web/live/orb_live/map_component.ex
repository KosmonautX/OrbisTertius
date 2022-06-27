defmodule PhosWeb.OrbLive.MapComponent do
  use PhosWeb, :live_component

  alias PhosWeb.Util.{Viewer,ImageHandler}
  alias Phos.Action
  alias Phos.Users

  @impl true
  def update(assigns, socket) do
    # If user has ":home, :work" in addresses, set the lat and lng to :markerloc and send to map.js else use default
    {lat, lng} =
      if assigns[:addresses][assigns[:setloc]] do
        # import IEx; IEx.pry()
        List.last(assigns[:addresses][assigns[:setloc]])
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
  def handle_event("modalmap_setloc", %{"lng" => longitude, "lat" => latitude}, socket) do
    {:noreply, socket
      |> assign(:markerloc, %{latitude: latitude, longitude: longitude})}
  end

  @impl true
  def handle_event("save_loc", %{"lng" => longitude, "lat" => latitude}, socket) do
    user = socket.assigns.current_user

    record =
      cond do
        # Create private_profile with geolocation flow
        socket.assigns.current_user.private_profile == nil ->
          ecto_insert =
            %Users.Private_Profile{}
            |> Users.Private_Profile.changeset(%{user_id: user.id})
            |> Ecto.Changeset.put_embed(:geolocation, [%{id: to_string(socket.assigns.setloc), geohash: :h3.from_geo({String.to_float(latitude), String.to_float(longitude)}, 10), chronolock: DateTime.utc_now() |> DateTime.add(14 * 3600 * 24, :second) |> DateTime.to_unix(), location_description: nil}])
            |> Phos.Repo.insert()

          case ecto_insert do
            {:ok, record} ->
              send(self(), {:static_location_update, %{"locname" => socket.assigns.setloc ,"longitude" => String.to_float(longitude), "latitude" => String.to_float(latitude)}})
              {:ok, record}
            {:error, changeset} ->
              {:error, changeset}
          end

        # Insert geolocation where other loc already exists
        Enum.find(user.private_profile.geolocation, fn map -> map.id == to_string(socket.assigns.setloc) end) == nil ->
            changeset = Ecto.Changeset.change(user.private_profile)
            geolocation_changeset = Ecto.Changeset.change(%Users.Geolocation{}, %{id: to_string(socket.assigns.setloc), geohash: :h3.from_geo({String.to_float(latitude), String.to_float(longitude)}, 10), chronolock: DateTime.utc_now() |> DateTime.add(14 * 3600 * 24, :second) |> DateTime.to_unix(), location_description: nil})
            ecto_update =
              Ecto.Changeset.put_embed(changeset, :geolocation, [geolocation_changeset | user.private_profile.geolocation])
              |> Phos.Repo.update()

          case ecto_update do
            {:ok, record} ->
              send(self(), {:static_location_update, %{"locname" => socket.assigns.setloc ,"longitude" => String.to_float(longitude), "latitude" => String.to_float(latitude)}})
              {:ok, record}
            {:error, changeset} ->
              {:error, changeset}
          end

        # Update flow
        true ->
          {loc_updating, loc_no_update} = Enum.split_with(user.private_profile.geolocation, fn u -> u.id == to_string(socket.assigns.setloc) end)
          # if DateTime.utc_now() |> DateTime.to_unix() < List.first(loc_updating).chronolock do
          #   {:chronolocked, %{}}
          # else
            changeset = Ecto.Changeset.change(user.private_profile)
            geolocation_changeset = Ecto.Changeset.change(List.first(loc_updating), %{id: to_string(socket.assigns.setloc), geohash: :h3.from_geo({String.to_float(latitude), String.to_float(longitude)}, 10), chronolock: DateTime.utc_now() |> DateTime.add(14 * 3600 * 24, :second) |> DateTime.to_unix(), location_description: nil})
            ecto_update =
              Ecto.Changeset.put_embed(changeset, :geolocation, [geolocation_changeset | loc_no_update])
              |> Phos.Repo.update()

            case ecto_update do
              {:ok, record} ->
                send(self(), {:static_location_update, %{"locname" => socket.assigns.setloc ,"longitude" => String.to_float(longitude), "latitude" => String.to_float(latitude)}})
                {:ok, record}
              {:error, changeset} ->
                {:error, changeset}
            end
          # end
      end

    case record do
      {:ok, record} ->
        send(self(), {:user_profile_loc_update, %{"profile" => record}})
        {:noreply, socket
          |> put_flash(:info, "#{String.capitalize(to_string(socket.assigns.setloc))} location saved")
          |> push_patch(to: socket.assigns.return_to)}
      {:chronolocked, _} ->
        {:noreply, socket
          |> put_flash(:error, "#{String.capitalize(to_string(socket.assigns.setloc))} location not saved. Not yet 14 days")
          |> push_patch(to: socket.assigns.return_to)}
      {:error, _changeset} ->
        {:noreply, socket
          |> put_flash(:error, "Changeset error")
          |> push_patch(to: socket.assigns.return_to)}
    end
  end
end
