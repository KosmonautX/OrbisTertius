defmodule PhosWeb.UserMemoryChannel do
  use PhosWeb, :channel

  alias PhosWeb.Presence
  alias PhosWeb.Util.Viewer

  def join("memory:user:" <> id, _payload, socket) do
    if authorized?(socket, id) do
      Process.send_after(self(), :after_join, 1000)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("memory", {:formation, memory}, socket) do
    broadcast(socket, "memory_formation", memory)
    {:noreply, socket}
  end

  def handle_in("memory", {:action, memory}, socket) do
    broadcast(socket, "memory_assembly", memory)
    {:noreply, socket}
  end

  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_info({Phos.PubSub, {:memory, event}, %Phos.Message.Memory{} = memory}, socket) do
    push(socket, "memory_" <> to_string(event), %{"data" => [memory] |> Viewer.memory_mapper()})
    {:noreply, socket}
  end

  def handle_info(:after_join, %{assigns: %{current_user: user}} = socket) do
    case user do
      %{private_profile: %{geolocation: terr}} ->
        terr
        |> Enum.map(&({&1.id, &1.geohash}))
        |> Enum.map(fn {"live", hash} ->
          :h3.parent(hash, 8)
          |> :h3.k_ring(1)
          |> Phos.Mainland.Sphere.middle()
          _ -> []
        end)
        |> List.flatten()
        |> Enum.map(&({&1, terra_mapper(&1)}))
        |> Enum.into(%{})
        |> tap(&push(socket, "assembly_initiation", &1))
        |> Enum.map(fn {hash, _} -> terra_track(hash, socket) end)

        _ -> :ok
    end

    #Enum.map(&(Phos.PubSub.subscribe(&1)))
    #topic = Presence.user_topic(user.id)
    #Phoenix.PubSub.subscribe(socket.pubsub_server, topic, fastlane: {socket.transport_pid, socket.serializer, []})
    #Presence.track(self(), topic, "status", %{online: System.system_time(:second)})
    #push(socket, "presence_state", Presence.list(topic))

    {:noreply, socket}
  end

  def handle_info({presence_event, "memory:terra:" <> _hash, data}, socket) do
    push(socket, "assembly_" <> to_string(presence_event), Viewer.user_presence_mapper(data))
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    {:noreply, socket}
  end

  def handle_out(_event, _payload, socket) do
    {:noreply, socket}
  end

  def terra_track(hash, %{assigns: %{current_user: user}} = socket) when is_integer(hash) do
    terra_topic(hash)
    |> tap(&Phos.PubSub.subscribe(&1, fastlane: {socket.transport_pid, socket.serializer, []}))
    |> tap(&PhosWeb.Watcher.track(self(), &1, user))
  end

  defp terra_mapper(hash) when is_integer(hash) do
    %{
      hash: hash,
      midhash: hash |> Phos.Mainland.Sphere.middle(),
      town: hash |> Phos.Mainland.Sphere.locate(),
      living: terra_topic(hash) |> PhosWeb.Watcher.list_users() |> Viewer.user_presence_mapper()
    }
  end

  defp terra_topic(hash), do: "memory:terra:" <> Integer.to_string(hash)
end
