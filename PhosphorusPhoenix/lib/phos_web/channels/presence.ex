defmodule PhosWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :phos,
    pubsub_server: Phos.PubSub

  
  def init(_opts), do: {:ok, %{}}

  def handle_metas("memory:user:" <> user_id, %{leaves: leaves, joins: _joins}, _presence, state) do
    handle_leaves(leaves, user_id)

    {:ok, state}
  end
  def handle_metas(_topic, _gates, _presence, state), do: {:ok, state}

  def user_topic(user_id), do: "memory:user:#{user_id}"

  defp handle_leaves(leaves, user_id) do
    leaves
    |> Map.get("last_read", %{})
    |> get_in([Access.key(:metas, [])])
    |> Enum.map(fn %{rel_id: id} ->
      set_last_read(id, user_id)
    end)
  end

  defp set_last_read([], _user_id), do: :ok
  defp set_last_read(data, user_id), do: Phos.Folk.set_last_read(data, user_id)
end
