defmodule PhosWeb.UserPresence do

  alias Phos.Folk
  alias PhosWeb.Presence

  def online_folks(user_id) do
    Folk.friends_lite(user_id)
    |> Enum.reduce([], fn friend_id, acc ->
      Presence.user_topic(friend_id)
      |> Presence.get_by_key("status")
      |> Enum.to_list()
      |> Kernel.length()
      |> case do
        1 -> [friend_id | acc]
        _ -> acc
      end
    end)
  end
end
