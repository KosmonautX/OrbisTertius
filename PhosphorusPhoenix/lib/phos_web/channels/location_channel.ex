defmodule PhosWeb.UserLocationChannel do
  use PhosWeb, :channel
  alias PhosWeb.Util.Viewer
  alias Phos.Action
  alias Phos.PubSub

  @impl true
  @territorial_radius [8]

  def join("archetype:loc:" <> user_id , _payload, socket) do
    # if exists on the app
    # preload geolocation preferences of user_id
    if authorized?(socket, user_id) do
      #https://elixirforum.com/t/myapp-endpoint-broadcast-vs-phoenix-pubsub-broadcast-are-they-indentical/32380/2
    {:ok, socket
    |> assign(:user_id, user_id)
    |>assign(:geolocation, %{})}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("location_update", %{"name"=> name,"geohash"=> hash}, socket) when name in ["home", "work", "live"] do
    # check name against jwt using authorized
    #IO.puts " in paris #{inspect(socket.assigns.geolocation)}"
    updated_geolocation =
      get_and_update_in(socket.assigns.geolocation, Enum.map([name, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.parent(hash, 10), radius: 10}})
      |> case do
        {past, present} -> push_loc_reverie(socket, present, name, past == present[name][:geohash])
      end
    {:noreply, assign(socket, :geolocation, updated_geolocation)}
  end

  @impl true
  def handle_in("location_update", _payload, socket) do
    IO.puts("invalid payload location update")
    {:noreply, socket}
  end


  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # def handle_info(%{topic: _, event: event, payload: payload}, socket) do
  #   push(socket, event, payload)
  #   IO.inspect(event)
  #   {:noreply, socket}
  # end

  @impl true
  def handle_info({Phos.PubSub, {:orb, event}, %Action.Orb{} = orb}, socket) do
    push(socket, "orb_" <> to_string(event), %{"subscribed" => orb.topic, "data" => [orb] |> Viewer.fresh_orb_stream_mapper()})
    {:noreply, socket}
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp loc_subscriber(present, nil) do
    #IO.puts("subscribe #{inspect(present)}")
    present |> Enum.each(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
    present
  end

  defp loc_subscriber(present, past) do
    IO.puts("subscribe with past#{inspect(present)}")
    present -- past |> Enum.each(fn new -> new |> loc_topic() |> PubSub.subscribe() end)
    past -- present |> Enum.each(fn old-> old |> loc_topic() |> PubSub.unsubscribe() end)
    present
  end

  defp loc_fetch(present, nil) do
    %{"subscribed" => present, "data" => present |> Action.active_orbs_by_geohashes() |> Viewer.orb_mapper()}
  end

  defp loc_fetch(present, past) do
    %{"subscribed" => present, "data" => present -- past |> Action.active_orbs_by_geohashes() |> Viewer.orb_mapper()}
  end

  # defp loc_listener(topic, orb) do
  #   %{"subscribed" => topic, "data" => orb|> Viewer.orb_mapper()}
  # end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"


  defp push_loc_reverie(socket, present, name, false) do
    message = Enum.map(@territorial_radius, fn res -> :h3.parent(present[name][:geohash].hash, res) end)
      |> loc_subscriber(present[name][:geosub])
      |> loc_fetch(present[name][:geosub])
      |> Map.put("name", name)

    push(socket, "loc_reverie", message)

    put_in(present, [name, :geosub], message["subscribed"])
  end
  defp push_loc_reverie(_socket, present, _name, _), do: present
end
