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
    |> assign(:geolocation, %{home: %{geohash: %{hash: 623276216934563839}, orbs: []}})
    # |> assign(:orbs_home,
    #   Enum.map([8,9,10], fn res -> :h3.parent(socket.assigns.geolocation[:home][:geohash].hash,res) end)
    #     |> Phos.Action.get_orbs_by_geohashes()
    #     |> Enum.sort_by(&Map.fetch(&1, :inserted_at), :desc))
    #|> assign(:geolocation, User.get_location_pref())
  }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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

  def assign_empty_geolocation(socket) do
    assign(socket, :geolocation, %{live: %{geohash: %{}, orbs: []}, home: %{orbs: []}})
  end

  def handle_info(:geoinitiation, socket) do
    updated_geolocation =
    for loc <- Map.keys(socket.assigns.geolocation), into: %{} do
      if Map.has_key?(socket.assigns.geolocation[loc][:geohash], :hash) do
        neosubs = Enum.map([8,9,10], fn res -> :h3.parent(socket.assigns.geolocation[loc][:geohash].hash, res) end)
        |> loc_subscriber(socket.assigns.geolocation[loc][:geosub])
        updated_geo = put_in(socket.assigns.geolocation, [loc, :geosub], neosubs)
        |> put_in([loc, :orbs], Phos.Action.get_active_orbs_by_geohashes(neosubs))
        {loc, updated_geo[loc]}
      end
    end
    {:noreply, assign(socket, :geolocation, updated_geolocation)}
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
               |> put_in([:live, :orbs], Phos.Action.get_active_orbs_by_geohashes(neosubs))
          {orbed_geolocation, socket
          |> push_event("add_polygon", %{geo_boundaries: loc_boundary(latitude, longitude)})}
             else
               {geolocation_present, socket}
             end
         end

         IO.inspect(updated_geolocation)


    {:noreply, socket
    |> assign(:geolocation, updated_geolocation)
    |> push_event("centre_marker", %{latitude: latitude, longitude: longitude})}
  end

  @impl true
  def handle_event("delete", %{"id" => id, "locname" => name}, socket) do
    orb = Action.get_orb!(id)
    {:ok, _} = Action.delete_orb(orb)

    orblist = socket.assigns.geolocation[String.to_atom(name)].orbs |> Enum.reject(fn orb -> orb.id == id end)
    updated_geoloc = put_in(socket.assigns.geolocation, [String.to_atom(name), :orbs], orblist)

    {:noreply, assign(socket, :geolocation, updated_geoloc)}
  end

  @impl true
  def handle_info({PubSub, {:orb, :genesis}, message}, socket) do
    IO.puts("genesis #{inspect(message)}")
    {:noreply, socket}
  end

  def handle_info({PubSub, {:orb, :mutation}, message}, socket) do
    IO.puts("mutate #{inspect(message)}")
    {:noreply, socket}
  end


  def handle_info({PubSub, {:orb, :deactivation}, message}, socket) do
    IO.puts("deactivate #{inspect(message)}")
    {:noreply, socket}
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
