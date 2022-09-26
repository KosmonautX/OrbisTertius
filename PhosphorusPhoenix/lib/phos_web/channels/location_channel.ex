defmodule PhosWeb.UserLocationChannel do
  use PhosWeb, :channel
  alias PhosWeb.Menshen.Auth
  alias PhosWeb.Util.Viewer
  alias Phos.Action
  alias Phos.Users
  alias Phos.PubSub
  alias Phos.Geographer


  @impl true

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
    updated_geolocation = get_and_update_in(socket.assigns.geolocation, Enum.map([name, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.parent(hash, 10), radius: 10}})
    |> case do
         {past, present} ->
           unless past == present[name][:geohash] do
             message = Enum.map([8,9,10], fn res -> :h3.parent(present[name][:geohash].hash,res) end)
             |> loc_subscriber(present[name][:geosub])
             |> loc_fetch(present[name][:geosub])
             |> Map.put("name", name)

             push(socket, "loc_reverie", message)

             put_in(present, [name, :geosub], message["subscribed"])
           else
             present
           end
       end
    {:noreply, assign(socket, :geolocation, updated_geolocation)}
  end

  def handle_in("location_update", _payload, socket) do
    IO.puts("invalid payload location update")
    {:noreply, socket}
  end


  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
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

  def handle_info(event, socket) do
    IO.inspect(event)
    {:noreply, socket}
  end


  # Add authorization logic here as required. Process send_after for auth channel
  defp authorized?(socket, id) do
    case Auth.validate_user(socket.assigns.session_token) do
      {:ok , claims} ->
        if is_map(socket.assigns.user_agent) and claims["user_id"] == socket.assigns.user_agent["user_id"] and claims["user_id"] == id do
          true
        else
          false
        end
      { :error, _error } ->
        {:error,  :authentication_required}
    end
  end

  defp loc_subscriber(present, nil) do
    #IO.puts("subscribe #{inspect(present)}")
    present |>Enum.map(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
    present
  end

  defp loc_subscriber(present, past) do
    IO.puts("subscribe with past#{inspect(present)}")
    present -- past |> Enum.map(fn new -> new |> loc_topic() |> PubSub.subscribe() end)
    past -- present |>Enum.map(fn old-> old |> loc_topic() |> PubSub.unsubscribe() end)
    present
  end

  defp loc_fetch(present, nil) do
    %{"subscribed" => present, "data" => present |> Action.active_orbs_by_geohashes() |> Viewer.fresh_orb_stream_mapper()}
  end

  defp loc_fetch(present, past) do
    %{"subscribed" => present, "data" => present -- past |> Action.active_orbs_by_geohashes() |> Viewer.fresh_orb_stream_mapper()}
  end

  defp loc_listener(topic, orb) do
    %{"subscribed" => topic, "data" => orb|> Viewer.fresh_orb_stream_mapper()}
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

end
