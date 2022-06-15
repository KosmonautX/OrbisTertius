defmodule PhosWeb.OrbLive.Index do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Action
  alias Phos.Action.Orb
  alias Phos.PubSub

  @impl true
  def mount(_params, _session, socket) do
    send(self(), :geoinitiation)
    {:ok, socket
    # |> assign(:geolocation, %{home: %{geohash: %{hash: 623276217027067903}}})
    |> assign(:geolocation, %{})
    |> assign(:orbs, %{home: [], work: [], live: []})
  }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :sethome, _params) do
    socket
    |> assign(:page_title, "Set Home Location")
    |> assign(:setloc, :home)
  end

  defp apply_action(socket, :setwork, _params) do
    socket
    |> assign(:page_title, "Set Work Location")
    |> assign(:setloc, :work)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Orb")
    |> assign(:orb, Action.get_orb!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Orb")
    |> assign(:orb, %Orb{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Orbs")
  end

  def handle_info(:geoinitiation, socket) do
    updated_geolocation =
      for loc <- Map.keys(socket.assigns.geolocation), into: %{} do
        if Map.has_key?(socket.assigns.geolocation[loc][:geohash], :hash) do
          neosubs = Enum.map([8,9,10], fn res -> :h3.parent(socket.assigns.geolocation[loc][:geohash].hash, res) end)
          |> loc_subscriber(socket.assigns.geolocation[loc][:geosub])
          updated_geo = put_in(socket.assigns.geolocation, [loc, :geosub], neosubs)
          {loc, updated_geo[loc]}
        end
      end

    updated_orblist =
      Enum.reduce(updated_geolocation, %{}, fn {key,value}, acc ->
        acc
        |> Map.put(key, value |> Map.get(:geosub) |> Action.get_active_orbs_by_geohashes())
      end)

    {:noreply, socket
        |> assign(:geolocation, updated_geolocation)
        |> assign(:orbs, updated_orblist)}
  end

  def handle_info({:locnameupdated, geolocation}, socket) do
    {:noreply, socket
      |> assign(:geolocation, geolocation)}
  end

  @impl true
  def handle_event("live_location_update", %{"longitude" => longitude, "latitude" => latitude}, socket) do
    {updated_geolocation, socket} =
      get_and_update_in(socket.assigns.geolocation, Enum.map([:live, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.from_geo({latitude, longitude}, 10), radius: 10}})
      |> case do
           {past_geohash, geolocation_present} ->
             unless past_geohash == geolocation_present[:live][:geohash] do
               # pipe new geosubs into loc subscriber and pass old geosubs
               neosubs = Enum.map([8,9,10], fn res -> :h3.parent(geolocation_present[:live][:geohash].hash,res) end)
               |> loc_subscriber(geolocation_present[:live][:geosub])
               orbed_geolocation = put_in(geolocation_present, [:live, :geosub], neosubs)
          {orbed_geolocation, socket
          |> push_event("add_polygon", %{geo_boundaries: loc_boundary(latitude, longitude)})}
             else
               {geolocation_present, socket}
             end
         end

    # Add live orbs to orblist
    orblist = updated_geolocation |> Map.get(:live) |> Map.get(:geosub) |> Action.get_active_orbs_by_geohashes()
    updated_orblist = put_in(socket.assigns.orbs, [:live], orblist)

    {:noreply, socket
    |> assign(:geolocation, updated_geolocation)
    |> assign(:orbs, updated_orblist)
    |> push_event("centre_marker", %{latitude: latitude, longitude: longitude})}
  end

  @impl true
  def handle_event("delete", %{"id" => id, "locname" => name}, socket) do
    orb = Action.get_orb!(id)
    {:ok, _} = Action.delete_orb(orb)

    orblist = socket.assigns.orbs[String.to_atom(name)] |> Enum.reject(fn orb -> orb.id == id end)
    updated_orblist = put_in(socket.assigns.orbs, [String.to_atom(name)], orblist)
    orb_loc_publisher(orb, :deactivation, orb.central_geohash |> :h3.k_ring(1))

    {:noreply, assign(socket, :orbs, updated_orblist)}
  end

  @impl true
  def handle_info({PubSub, {:orb, :genesis}, message}, socket) do
    IO.puts("genesis #{inspect(message)}")

    updated_orblist =
      for loc <- Map.keys(socket.assigns.geolocation), into: %{} do
        if :h3.parent(message.central_geohash, 8) in socket.assigns.geolocation[loc][:geosub] do
          orblist = [message | socket.assigns.orbs[loc]]
          updated_orb = put_in(socket.assigns.orbs, [loc], orblist)
          {loc, updated_orb[loc]}
        else
          {loc, socket.assigns.orbs[loc]}
        end
      end

      # ISSUE: Duplicate posts if home/work same as live.

    {:noreply, socket
    |> assign(:orbs, updated_orblist)}
  end

  def handle_info({PubSub, {:orb, :mutation}, message}, socket) do
    IO.puts("mutate #{inspect(message)}")

    updated_orblist =
      for loc <- Map.keys(socket.assigns.geolocation), into: %{} do
        if :h3.parent(message.central_geohash, 8) in socket.assigns.geolocation[loc][:geosub] do
          replace_orb_index = Enum.find_index(socket.assigns.orbs[loc], fn elem -> elem.id == message.id end)
          updated_orb = List.replace_at(socket.assigns.orbs[loc], replace_orb_index, message)
          {loc, updated_orb}
        else
          {loc, socket.assigns.orbs[loc]}
        end
      end

    {:noreply, socket
      |> assign(:orbs, updated_orblist)}
  end


  def handle_info({PubSub, {:orb, :deactivation}, message}, socket) do
    IO.puts("deactivate #{inspect(message)}")

    updated_orblist =
      for loc <- Map.keys(socket.assigns.geolocation), into: %{} do
        if :h3.parent(message.central_geohash, 8) in socket.assigns.geolocation[loc][:geosub] do
          orblist = socket.assigns.orbs[loc] |> Enum.reject(fn orb -> orb.id == message.id end)
          updated_orb = put_in(socket.assigns.orbs, [loc], orblist)
          {loc, updated_orb[loc]}
        else
          {loc, socket.assigns.orbs[loc]}
        end
      end

    {:noreply, socket
    |> assign(:orbs, updated_orblist)}
  end

  defp list_orbs do
    Action.list_orbs()
  end

  defp loc_subscriber(present, nil) do
    present |>Enum.map(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
    present
  end

  defp loc_subscriber(present, past) do
    present -- past |> Enum.map(fn old -> old |> loc_topic() |> Phos.PubSub.unsubscribe() end)
    past -- present |>Enum.map(fn new-> new |> loc_topic() |> Phos.PubSub.subscribe() end)
    present
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

  defp orb_loc_publisher(orb, event, to_locations) do
    to_locations |> Enum.map(fn loc-> Phos.PubSub.publish(orb, {:orb, event}, loc_topic(loc)) end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

  defp loc_boundary(lat, lon) do
    :h3.from_geo({lat, lon}, 8)
    |> :h3.to_geo_boundary()
    |> Enum.map(fn tuple -> Tuple.to_list(tuple) end)
  end

end
