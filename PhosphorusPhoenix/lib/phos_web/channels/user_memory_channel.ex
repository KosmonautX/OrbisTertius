defmodule PhosWeb.UserMemoryChannel do
  use PhosWeb, :channel
  alias PhosWeb.Util.Viewer

  def join("memory:user:" <> id, _payload, socket) do
    if authorized?(socket, id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("memory", {:formation, memory}, socket) do
    broadcast(socket, "memory_formation", memory)
    {:noreply, socket}
  end

  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in(_anything, payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_info({Phos.PubSub, {:memory, event}, %Phos.Message.Memory{} = memory}, socket) do
    push(socket, "memory_" <> to_string(event), %{"data" => [memory] |> Viewer.memory_mapper()})
    {:noreply, socket}
  end

  def handle_info(:after_join, %{assigns: assigns} = socket) do
    track_online_user_by_geo(socket, assigns.current_user)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    push(socket, "memory_", %{"data" => [msg] |> Viewer.memory_mapper()})
    {:noreply, socket}
  end

  defp track_online_user_by_geo(%{transport_pid: pid} = socket, user) do
    key = "online_geos"
    geo_key = "some_key"
    push(socket, "#{key}_state", PhosWeb.Presence.list(key))
    PhosWeb.Presence.track(pid, "online_geos", geo_key, %{user_id: user.id})
  end

  defp track_online_user(%{transport_pid: pid} = socket, user) do
    key = "online_users"
    push(socket, "#{key}_state", PhosWeb.Presence.list(key))
    PhosWeb.Presence.track(pid, key, user.id, %{online_at: System.system_time(:second)})
  end
end
