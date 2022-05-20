defmodule PhosWeb.UserChannel do
  use PhosWeb, :channel
  alias PhosWeb.Menshen.Auth
  alias Phos.Message
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
  # broadcast to everyone in the current topic (archetype:usr).
  @impl true
  def handle_in("shout", payload, socket) do
    if check_territory?(socket) do
      # add user to source information
      payload = payload
      |> Map.put("source", socket.assigns.user_agent["user_id"])
      |> Map.put("source_archetype", "USR")
      # Create Echo :OK and :ERROR handling
      case Message.create_echo(payload) do
        {:ok, struct} ->
          echo = Map.take(struct, [:destination, :source, :source_archetype, :destination_archetype, :message, :inserted_at, :subject, :subject_archetype])
          |> Map.update!(:inserted_at, &(&1 |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix() |> to_string()))
          broadcast socket, "shout", echo #broadcast to both channels from and to, first the source
          PhosWeb.Endpoint.broadcast_from!(self(), "archetype:usr:" <> echo.destination, "shout", echo) #then  broadcast to destination as well
          #fyring and forgetting
          Phos.Fyr.Task.start_link(Pigeon.FCM.Notification.new({:topic, "USR." <> echo.destination}, %{"title" => "Message from #{socket.assigns.user_agent["username"]}", "body" => echo.message},echo))
        {:error, changeset} ->
          IO.inspect "Message Create Echo failed:",  changeset
      end
      {:noreply, socket}
    else
      IO.puts("geolocation unauthorized")
      {:noreply, socket}
    end
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

  defp check_territory?(socket) do
    case Auth.validate(socket.assigns.session_token) do
      {:ok , claims} ->
        # import IEx; IEx.pry

        # ==== test target territories

        # target_territory = %{"geohash" => "8a652634e00ffff", "target" => 10} # not safe within parent
        target_territory = %{"geohash" => "8a652634e62ffff", "target" => 10} # safe within parent

        # target_territory = %{"latlon" => {1.460991, 103.835827}, "target" => 9} # not safe within parent
        # target_territory = %{"latlon" => {1.4527860925434901, 103.81559241238618}, "target" => 9} # safe within parent

        case Map.keys(target_territory) do
          ["geohash", "target"] ->
            targeth3index = target_territory["geohash"]
            |> to_charlist()
            |> :h3.from_string()

            check_geoauth?(claims["territory"], targeth3index)

          ["latlon", "target"] ->
            targeth3index = :h3.from_geo(target_territory["latlon"], target_territory["target"])

            check_geoauth?(claims["territory"], targeth3index)

          _ -> false
        end
      { :error, _error } ->
        {:error,  :authentication_required}
    end
  end

  defp check_geoauth?(jwt_territories, target_h3index) do
    jwt_territories
    |> Map.values()
    |> Enum.map(fn %{"hash" => jwt_hash, "radius" => jwt_radius} ->
      if (:h3.parent(target_h3index, jwt_radius) |> :h3.to_string()) == to_charlist(jwt_hash) do
        true
      else
        false
      end
    end)
    |> Enum.member?(true)
  end
end
