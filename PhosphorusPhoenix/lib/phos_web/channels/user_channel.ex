defmodule PhosWeb.UserChannel do
  use PhosWeb, :channel
  alias PhosWeb.Menshen.Auth
  alias Phos.Message
  alias Phos.Action
  alias Phos.Pubsub
  alias Phos.Geographer
  alias Phos.External.ForeignAPI

  @impl true
  def join("archetype:usr:" <> id , _payload, socket) do
    if authorized?(socket, id) do
      send(self(), :initiation)
      {:ok, socket
      |> assign(:user_channel_id, id)
      |> assign(:geolocation, %{})
      |> assign(:geosubscriptions, [])}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # maintain subscriber lists for live home work on socket
  def handle_in("geocenter", geolocation,  socket) do
    geo_jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiREFBb2hnc0xNcFFQbXNicGJ2Z1E1UEVQdXkyMiIsInJvbGUiOiJwbGViIiwidGVycml0b3J5Ijp7ImhvbWUiOnsicmFkaXVzIjo4LCJoYXNoIjoiODg2NTI2MzYwNWZmZmZmIn0sImxpdmUiOnsicmFkaXVzIjo4LCJoYXNoIjoiODg2NTI2YWMzZGZmZmZmIn0sIndvcmsiOnsicmFkaXVzIjo4LCJoYXNoIjoiODg2NTI2YWMzNWZmZmZmIn19LCJ1c2VybmFtZSI6IkFkbWluaXN0cmF0b3IiLCJpYXQiOjE2NTQyNTgxNjQsImV4cCI6MTY1NDI1OTM2NCwiaXNzIjoiUHJpbmNldG9uIiwic3ViIjoiU2NyYXRjaEJhYyJ9.TVQq94RpT1n6Lb42xQNxrf97Wszj8O_meBp6V8yrcUs"
    # watch out for backpressure genstage here Producer/Consumer
    ref = socket_ref(socket)
    Task.start(fn ->
      #subscription inside tasks
      Geographer.parse_territories(socket, geolocation)
      |> Enum.map(fn orb ->
        case orb do
          {:ok, orb} ->
            IO.inspect(orb)
            broadcast socket, "shout", orb
          {:error, message} ->
            IO.inspect(message)
        end
      end)
    end)
    {:noreply, socket} #|> geosubscribing(geolocation)}
  end

  # Channels can be used in a request/response fashion
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
      # Phos.External.ForeignAPI.get_fyr_id(socket.assigns.user_channel_id)
      # |> Phos.Repo.

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

  defp geosubscribing(socket, geolocation) do
    geolocation
    |> Enum.map(fn {k,v} ->
      unless socket[k]["hash"] == v["hash"] do
        #replace with geosubscriptions
      end
    end)
  end
end
