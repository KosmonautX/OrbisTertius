defmodule PhosWeb.UserChannel do
  use PhosWeb, :channel
  alias PhosWeb.Menshen.Auth

  @impl true
  def join("archetype:usr:" <> id , _payload, socket) do
    if authorized?(socket, id) do
      send(self(), :initiation)
      {:ok, socket |> assign(:user_channel_id, id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (agent:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    payload = payload
    #|> Map.put("name", socket.assigns.user_agent["username"])
    |> Map.put("source", socket.assigns.user_agent["user_id"])
    |> Map.put("source_archetype", "USR")
    case Phos.Echo.changeset(%Phos.Echo{}, payload) |> Phos.Repo.insert do
      {:ok, struct} ->
        echo = Map.take(struct, [:destination,:source, :source_archetype, :destination_archetype, :message, :inserted_at])
        |> Map.update!(:inserted_at, &(&1 |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix() |> to_string()))
        broadcast socket, "shout", echo #broadcast to both channels from and to, first the source
        PhosWeb.Endpoint.broadcast_from!(self(), "archetype:usr:" <> echo.destination,"shout", echo) #then  broadcast to destination as well
        try do
          #Construct Notification for Destination
	        case Phos.Fyr.Message.push(Pigeon.FCM.Notification.new({:topic, "/topics/" <> "USR." <> echo.destination},
                    %{"title" => "Message from #{socket.assigns.user_agent["username"]}", "body" => echo.message},
                    echo)) do
            %{response: :success } -> :ok
            %{error: reason} -> IO.puts("Error: #{reason}")
          end
        rescue
          e in RuntimeError -> IO.puts e
        end
      {:error, changeset} ->
        IO.puts changeset
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:initiation,  socket) do
    Phos.Echo.usr_call(socket.assigns.user_channel_id) # from user_id
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
    {:noreply,socket}
  end

  # Add authorization logic here as required.
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
end
