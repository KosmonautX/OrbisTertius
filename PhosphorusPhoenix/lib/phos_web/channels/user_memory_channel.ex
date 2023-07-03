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
      %{public_profile: %{territories: terr}} ->
        terr
        |> Phos.Mainland.Sphere.middle()
        |> Enum.map(&(terra_topic(&1)))

      _ -> :ok
    end
    #Enum.map(&(Phos.PubSub.subscribe(&1)))

    topic = Presence.user_topic(user.id)
    Phoenix.PubSub.subscribe(socket.pubsub_server, topic, fastlane: {socket.transport_pid, socket.serializer, []})
    Presence.track(self(), topic, "status", %{online: System.system_time(:second)})
    push(socket, "presence_state", Presence.list(topic))

    {:noreply, socket}
   end


  def handle_info(msg, socket) do
    IO.inspect(msg)
    push(socket, "memory_", %{"data" => [msg] |> Viewer.memory_mapper()})
    {:noreply, socket}
  end

  def handle_out(_event, _payload, socket) do
    {:noreply, socket}
  end

  def terra_topic(hash) when is_integer(hash) do
    "memory:terra:" <> Integer.to_string(hash) |> Phos.PubSub.subscribe()
  end

end
