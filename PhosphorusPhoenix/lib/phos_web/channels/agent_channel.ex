defmodule PhosWeb.AgentChannel do
  use PhosWeb, :channel

  @impl true
  def join("agent:" <> id , payload, socket) do
    if authorized?(payload) do
      {:ok, socket |> assign(:archetype_id, id)}
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
    |> Map.put("from", "1")
    Phos.Echo.changeset(%Phos.Echo{}, payload) |> Phos.Repo.insert
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

    @impl true
  def handle_info(:after_join,  socket) do
    Phos.Echo.agent_call("1")
    |> Enum.each(fn echoes -> push(socket, "reverie", %{
                                         from: echoes.from,
                                         to: echoes.to,
                                         archetype: echoes.type,
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
