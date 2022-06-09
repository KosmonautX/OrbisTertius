defmodule PhosWeb.LocationChannel do
  use PhosWeb, :channel
  alias PhosWeb.Menshen.Auth
  alias Phos.Message
  alias Phos.Action
  alias Phos.Users
  alias Phos.PubSub
  alias Phos.Geographer
  alias PhosWeb.Util.Migrator

  @impl true

  def join("archetype:loc:" <> loc_id , _payload, socket) do
    {:ok, socket
      |>assign(:geolocation, %{})}
  end

  def handle_in("location_update", %{"name"=> name,"geohash"=> hash}, socket) when name in ["home", "work", "live"] do
    # check name against jwt using authorized
    updated_geolocation = get_and_update_in(socket.assigns.geolocation, Enum.map([name, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.parent(hash, 10), radius: 10}})
    |> case do
         {past, present} ->
           unless past == present[name][:geohash] do
             neosubs = Enum.map([8,9,10], fn res -> :h3.parent(present[name][:geohash].hash,res) end)
             |> loc_subscriber(present[name][:geosub])
             put_in(present, [name, :geosub], neosubs)
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
  @impl true
  def handle_in("ping", payload, socket) do
    IO.inspect(socket)
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (archetype:usr).
  @impl true
  def handle_in("shout", payload, socket) do
    # add user to source information
    payload = payload
    |> Map.put("source", socket.assigns.user_agent["user_id"])
    |> Map.put("source_archetype", "USR")
    # Create Echo :OK and :ERROR handling
    case Message.create_echo(payload) do
      {:ok, struct} ->
        echo = Map.take(struct, [:destination, :source, :source_archetype, :destination_archetype, :message, :inserted_at, :subject, :subject_archetype])
        |> Map.update!(:inserted_at, &(&1 |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix() |> to_string()))
        broadcast socket, "shout", echo #broadcast to both channels from and to, first the source as shout event
        PhosWeb.Endpoint.broadcast_from!(self(), "archetype:usr:" <> echo.destination, "shout", echo) #then  broadcast to destination as well
        #fyring and forgetting
        Phos.Fyr.Task.start_link(Pigeon.FCM.Notification.new({:topic, "USR." <> echo.destination}, %{"title" => "Message from #{socket.assigns.user_agent["username"]}", "body" => echo.message},echo))
      {:error, changeset} ->
        IO.puts("Message Create Echo failed: #{inspect(changeset)}")
    end
    {:noreply, socket}
  end

  defp loc_subscriber(present, nil) do
    IO.puts("subscribe #{inspect(present)}")
    present |>Enum.map(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
  end

  defp loc_subscriber(present, past) do
    IO.puts("subscribe with past#{inspect(present)}")
    present -- past |> Enum.map(fn old -> old |> loc_topic() |> Phos.PubSub.unsubscribe() end)
    past -- present |>Enum.map(fn new-> new |> loc_topic() |> Phos.PubSub.subscribe() end)
    present
  end

  defp loc_reverie(present, nil, socket) do
    present |> Action.get_orbs_by_geohashes()
    present
  end

  defp loc_reverie(present, past, socket) do
    past -- present |>  Action.get_orbs_by_geohash()
    present
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

end
