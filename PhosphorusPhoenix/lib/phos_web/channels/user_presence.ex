defmodule PhosWeb.UserPresence do

  alias Phos.Folk
  alias PhosWeb.Presence

  def friend_online_status(socket, user, options \\ [])
  def friend_online_status(%{transport_pid: pid} = socket, user, opts) when is_pid(pid) and is_map(user) do
    topic = presence_topic(user.id)
    Presence.track(pid, topic, user.id, body(true))

    %{data: friends} = Folk.friends(user)

    Enum.map(friends, fn %{friend_id: id} ->
      friend_topic = presence_topic(id)
      Phos.PubSub.subscribe(friend_topic)
      root = Keyword.get(opts, :relation)

      Presence.list(friend_topic)
      |> Enum.map(fn {key, val} ->
        force_join(pid, topic, key, body(%{foreign: true, relation_id: root}))
        force_join(pid, friend_topic, user.id, body(%{foreign: false, relation_id: root}))
      end)
    end)

    :ok
  end
  def friend_online_status(_socket, _user, _opts), do: :ok

  defp body(self) when is_boolean(self) do
    %{self: self, online_from: System.system_time(:second), foreign: false}
  end
  defp body(map), do: Map.merge(body(false), map)

  defp presence_topic(user_id), do: "memory:user:#{user_id}"

  defp force_join(pid, topic, key, data) do
    case Presence.track(pid, topic, key, data) do
      {:ok, _ref} -> :ok
      {:error, {:already_tracked, owner, current_topic, current_key}} ->
        %{metas: [meta | _rest]} = Presence.get_by_key(current_topic, current_key)
        Presence.update(owner, current_topic, current_key, Map.put(meta, :relation_id, Map.get(data, :relation_id)))
      _ -> :ok
    end
  end
end
