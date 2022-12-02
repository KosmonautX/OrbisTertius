defmodule PhosWeb.API.FriendJSON do
  def index(%{friends: friends}) do
    %{data: Enum.map(friends, &friend_json/1)}
  end

  def paginated(%{relations: data, meta: meta}) do
    %{data: Enum.map(data, &relation_json/1), meta: meta}
  end

  def paginated(%{friends: friends}) do
    %{data: Enum.map(friends.data, &friend_json/1), meta: friends.meta}
  end

  def show(%{friend: friend}), do: friend_json(friend)
  def show(%{relation: relation}), do: %{data: relation_json(relation)}

  def relation_error(%{reason: reason}) when is_bitstring(reason) do
    %{
      state: "error",
      reason: reason
    }
  end

  def relation_error(%{reason: changeset}) do
    messages =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
      |> Enum.map(fn {key, msgs} ->
        Enum.map(msgs, fn m -> "#{key} #{m}" end)
      end)
      |> List.flatten()

    %{
      state: "error",
      messages: messages,
    }
  end

  defp friend_json(user), do: PhosWeb.Util.Viewer.user_mapper(user)
  defp relation_json(user), do: PhosWeb.Util.Viewer.user_relation_mapper(user)
end
