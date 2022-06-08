defmodule PhosWeb.UserChannel do
  use PhosWeb, :channel
  alias PhosWeb.Menshen.Auth
  alias Phos.Message
  alias Phos.Action
  alias Phos.PubSub
  alias Phos.Geographer
  alias Phos.External.HeimdallrClient

  @impl true

  def join("archetype:usr:" <> id , _payload, socket) do
    if authorized?(socket, id) do
      send(self(), :initiation)
      {:ok, socket
      |> assign(:user_channel_id, id)
      |> assign(:geolocation, %{})}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("location_update", %{"name"=> name,"geohash"=> hash}, socket) do
    # check name against jwt using authorized
    updated_geolocation = get_and_update_in(socket.assigns.geolocation, Enum.map([name, :geohash], &Access.key(&1, %{})), &{&1, %{hash: :h3.parent(hash, 10), radius: 10}})
    |> case do
         {past, present} -> unless past == present[name][:geohash] do
             put_in(present, [name, :geosub],
               Enum.map([8,9,10], fn res -> :h3.parent(present[name][:geohash].hash,res) end)
               |> loc_subscriber(present[name][:geosub])
               |> loc_reverie(present[name][:geosub], socket)
               )
             else
               present
             end
           end

    {:noreply, assign(socket, :geolocation, updated_geolocation)}
  end

000  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
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

  @impl true
  def handle_info(:initiation,  socket) do
    Message.usr_call(socket.assigns.user_channel_id) # from user_id
    |> Enum.each(fn echoes -> push(socket, "reverie", %{
                                           source: echoes.source,
                                           destination: echoes.destination,
                                           source_archetype: echoes.source_archetype,
                                           destination_archetype: echoes.destination_archetype,
                                           subject_archetype: echoes.subject_archetype,
                                           subject: echoes.subject,
                                           message: echoes.message,
                                           time: DateTime.from_naive!(echoes.inserted_at,"Etc/UTC") |> DateTime.to_unix()
                                   }) end)

    # if user that exists on phone, exists on postgres (new models)
    # do returning user pathway
    # else migrate user from nodejs(dynamodb) and create model on postgres
    if (Phos.Repo.get_by(Phos.Users.User, fyr_id: socket.assigns.user_channel_id) == nil) do

      # user_payload = Phos.External.HeimdallrClient.get_dyn_user(socket.assigns.user_channel_id)
      user_payload = Phos.External.HeimdallrClient.get_dyn_user("DAAohgsLMpQPmsbpbvgQ5PEPuy22")

      geo_map = for loc <- Map.keys(user_payload["geolocation"]) do
        user_payload["geolocation"][loc]
        |> Map.put("type", loc)
        |> Map.put("geohash", :h3.from_string(to_charlist(Map.get(user_payload["geolocation"][loc]["geohashing"], "hash"))))
        |> Map.put("radius", Map.get(user_payload["geolocation"][loc]["geohashing"], "radius"))
      end

      Phos.Users.create_user(%{"username" => user_payload["payload"]["username"], "fyr_id" => socket.assigns.user_channel_id, "media" => user_payload["payload"]["media"], "profile" => %{"birthday" => user_payload["payload"]["birthday"], "bio" => user_payload["payload"]["bio"]}, "profile_pic" => user_payload["payload"]["profile_pic"] , "geohash"=> geo_map})

    end
    # IO.inspect(socket.assigns)
    {:noreply,socket}
   end

  # Add authorization logic here as required. Process send_after for auth channel
  defp authorized?(socket, id) do
    case Auth.validate(socket.assigns.session_token) do
      {:ok , claims} ->
        if claims["user_id"] == socket.assigns.user_agent["user_id"] and claims["user_id"] == id do
          true
        else
          false
        end
      { :error, _error } ->
        {:error,  :authentication_required}
    end
  end

  defp loc_subscriber(present, nil) do
    IO.puts("subscribe #{inspect(present)}")
    present |>Enum.map(fn new-> Phos.PubSub.subscribe(loc_topic(new)) end)
    present
  end

  defp loc_subscriber(present, past) do
    IO.puts("subscribe with past#{inspect(present)}")
    present -- past |> Enum.map(fn old -> old |> loc_topic() |> Phos.PubSub.unsubscribe() end)
    past -- present |>Enum.map(fn new-> new |> loc_topic() |> Phos.PubSub.subscribe() end)
    present
  end

  defp loc_reverie(present, nil, socket) do
    present |> Enum.map(fn new-> %{new =>  new |> Action.get_orbs_by_geohash()} end)
    present
  end

  defp loc_reverie(present, past, socket) do
    past -- present |>Enum.map(fn new-> %{new => new |>  Action.get_orbs_by_geohash()} end)
    present
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

end
