defmodule PhosWeb.UserChannel do
  use PhosWeb, :channel

  @impl true
  def join("archetype:usr:" <> id , payload, socket) do
    IO.inspect(id)
    if authorized?(payload) do
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
    |> Map.put("source", "1")
    |> Map.put("source_archetype", "USR")
    Phos.Echo.changeset(%Phos.Echo{}, payload) |> Phos.Repo.insert
    IO.inspect payload
    broadcast socket, "shout", payload #broadcast to both channels from and to, first the source
    PhosWeb.Endpoint.broadcast_from!(self(), "archetype:usr:" <> payload["destination"] , "shout", payload) #then  broadcast to destination as well
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
                                         message: echoes.message,
                                         time: DateTime.from_naive!(echoes.inserted_at,"Etc/UTC") |> DateTime.to_unix()
                                 }) end)
    {:noreply,socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
