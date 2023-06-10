defmodule PhosWeb.LocationMemoryChannel do
  use PhosWeb, :channel

  alias PhosWeb.Presence

  def join("memory:location:" <> loc, %{"user_id" => user_id} = _payload, socket) do
    if authorized?(socket, user_id) do
      send(self(), :after_join_location)
      {:ok, assign(socket, :location, loc)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_message", %{"message" => msg}, %{topic: "memory:location:" <> key, assigns: assigns} = socket) do
    broadcast(socket, "#{key}_state", %{
      message: msg,
      user: PhosWeb.Util.Viewer.user_mapper(assigns.current_user)
    })
    {:reply, {:ok, "sent"}, socket}
  end

  def handle_info(:after_join_location, %{assigns: assigns, transport_pid: pid} = socket) do
    push(socket, "location_state", Presence.list("location_state"))

    Presence.track(pid, "location_state", assigns.location, %{
      user_id: assigns.current_user.id
    })

    {:noreply, socket}
  end
end
