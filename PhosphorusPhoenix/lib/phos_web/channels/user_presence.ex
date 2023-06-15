defmodule PhosWeb.UserPresence do

  alias Phos.Folk
  alias PhosWeb.Presence

  def friend_online_status(%{transport_pid: pid} = socket, user) when is_pid(pid) and is_map(user) do
    topic = "online_user:#{user.id}"
    Presence.track(pid, topic, user.id, body(true))

    %{data: friends} = Folk.friends(user)

    Enum.map(friends, fn %{friend_id: id} ->
      friend_topic = "online_user:#{id}"
      Phos.PubSub.subscribe(friend_topic)

      Presence.list(friend_topic)
      |> Enum.map(fn {key, val} ->
        Presence.track(pid, topic, key, body())
        Presence.track(pid, friend_topic, user.id, body())
        IO.inspect({key, val})
      end)
    end)

    :ok
  end
  def friend_online_status(_socket, _user), do: :ok

  defp body(self \\ false) do
    %{self: self, online_from: System.system_time(:second)}
  end

  defp pubsub_server(%{pubsub_server: server} = socket), do: server
  defp pubsub_server(_socket), do: Phos.PubSub
end
