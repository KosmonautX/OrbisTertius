defmodule PhosWeb.OrbLive.Index do
  use PhosWeb, :live_view

  alias Phos.Action
  alias Phos.Action.Orb
  alias Phos.PubSub

  @impl true
  def mount(params, _session, socket) do
    #send(self(), :geoinitiation)

    {:ok,
     socket
     |> assign(:geolocation, %{"all" => Phos.Action.list_all_active_orbs()})
     |> assign(:addresses, %{"all" => ["all"]})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> apply_action(socket.assigns.live_action, params)}
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
    {geolocation, addresses} =
      case socket.assigns do
        %{current_user: %{private_profile: %{geolocation: _}}} ->
          geos =
            for geoloc <- socket.assigns.current_user.private_profile.geolocation do
              Enum.reduce([8, 9, 10], socket.assigns.geolocation, fn res, acc ->
                Map.put(
                  acc,
                  :h3.parent(geoloc.geohash, res),
                  Action.get_active_orbs_by_geohashes([:h3.parent(geoloc.geohash, res)])
                )
              end)
            end
            |> Enum.reduce(fn x, acc ->
              Map.merge(acc, x)
            end)

          address =
            for loc <- socket.assigns.current_user.private_profile.geolocation, into: %{} do
              {String.to_atom(loc.id),
               Enum.map([8, 9, 10], fn res -> :h3.parent(loc.geohash, res) end)}
            end

          loc_subscriber(Map.keys(geos), Map.keys(socket.assigns.geolocation))

          {geos, address}

        _ ->
          {%{}, %{}}
      end

    {:noreply,
     socket
     |> assign(:geolocation, geolocation)
     |> assign(:addresses, addresses)}
  end

  def handle_info(
        {:static_location_update,
         %{"locname" => locname, "longitude" => longitude, "latitude" => latitude}},
        socket
      ) do
    geos =
      Enum.reduce([8, 9, 10], socket.assigns.geolocation, fn res, acc ->
        Map.put(
          acc,
          :h3.parent(:h3.from_geo({latitude, longitude}, 10), res),
          Action.get_active_orbs_by_geohashes([
            :h3.parent(:h3.from_geo({latitude, longitude}, 10), res)
          ])
        )
      end)

    loc_subscriber(Map.keys(geos), Map.keys(socket.assigns.geolocation))

    {_prev_address, updated_addresses} =
      get_and_update_in(
        socket.assigns.addresses,
        Enum.map([locname], &Access.key(&1, %{})),
        &{&1,
         Enum.map([8, 9, 10], fn res ->
           :h3.parent(:h3.from_geo({latitude, longitude}, 10), res)
         end)}
      )

    {:noreply,
     socket
     |> assign(:geolocation, geos)
     |> assign(:addresses, updated_addresses)
     |> push_event("centre_marker", %{latitude: latitude, longitude: longitude})}
  end

  def handle_info({:user_profile_loc_update, %{"profile" => profile}}, socket) do
    updated_user = put_in(socket.assigns.current_user, [Access.key(:private_profile)], profile)

    {:noreply,
     socket
     |> assign(:current_user, updated_user)}
  end

  @impl true
  def handle_event("live_location_update", %{"longitude" => longitude, "latitude" => latitude}, socket) do
    send(self(), {:static_location_update, %{"locname" => :live, "longitude" => longitude, "latitude" => latitude}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    orb = Action.get_orb!(id)
    orb_loc_publisher(orb, :deactivation, orb.locations |> Enum.map(fn orb -> orb.id end))
    {:ok, _} = Action.delete_orb(orb)

    {:noreply, socket}
  end

  @impl true

  def handle_info({PubSub, {:orb, :genesis}, message}, socket) do
    IO.puts("genesis #{inspect(message)}")

    updated_orbs =
      put_in(socket.assigns.geolocation, [message.topic], [
        message | socket.assigns.geolocation[message.topic]
      ])

    {:noreply,
     socket
     |> assign(:geolocation, updated_orbs)}
  end

  def handle_info({PubSub, {:orb, :mutation}, message}, socket) do
    IO.puts("mutate #{inspect(message)}")

    replace_orb_index =
      Enum.find_index(socket.assigns.geolocation[message.topic], fn orb ->
        orb.id == message.id
      end)

    updated_orb =
      List.replace_at(socket.assigns.geolocation[message.topic], replace_orb_index, message)

    updated_orblist = put_in(socket.assigns.geolocation, [message.topic], updated_orb)

    {:noreply,
     socket
     |> assign(:geolocation, updated_orblist)}
  end

  def handle_info({PubSub, {:orb, :deactivation}, message}, socket) do
    IO.puts("deactivate #{inspect(message)}")

    rejected_orblist =
      Enum.reject(socket.assigns.geolocation[message.topic], fn orb -> orb.id == message.id end)

    updated_orblist = put_in(socket.assigns.geolocation, [message.topic], rejected_orblist)

    {:noreply,
     socket
     |> assign(:geolocation, updated_orblist)}
  end


  @impl true
  def handle_event("live_location_update", %{"longitude" => longitude, "latitude" => latitude}, socket) do
    send(self(), {:static_location_update, %{"locname" => :live, "longitude" => longitude, "latitude" => latitude}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    orb = Action.get_orb!(id)
    orb_loc_publisher(orb, :deactivation, orb.locations |> Enum.map(fn orb -> orb.id end))
    {:ok, _} = Action.delete_orb(orb)

    {:noreply, socket}
  end

  defp loc_subscriber(present, []) do
    present |> Enum.map(fn new -> Phos.PubSub.subscribe(loc_topic(new)) end)
    present
  end

  defp loc_subscriber(present, past) do
    (present -- past) |> Enum.map(fn new -> new |> loc_topic() |> Phos.PubSub.subscribe() end)
    (past -- present) |> Enum.map(fn old -> old |> loc_topic() |> Phos.PubSub.unsubscribe() end)
    present
  end

  defp orb_loc_publisher(orb, event, to_locations) do
    to_locations
    |> Enum.map(fn loc ->
      Phos.PubSub.publish(%{orb | topic: loc}, {:orb, event}, loc_topic(loc))
    end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

  defp location_fetcher(value, geolocation) do
    value |> Enum.reduce([], fn hash, _acc -> geolocation[hash] end)
  end
end
