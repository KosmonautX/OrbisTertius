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

  def handle_metas("last_read", %{leaves: leaves}, _presence, state) do
    handle_absence(leaves)

    # IO.inspect(state)

    {:ok, state}
  end

  def handle_metas(topic, %{leaves: leaves, joins: joins}, presence, state) do
    # TODO: need to implement
    IO.inspect([
      topic: topic,
      leaves: leaves,
      joins: joins,
      presence: presence
    ])

    {:ok, state}
  end

  defp handle_absence(leaves) do
    Enum.map(leaves, fn {key, %{metas: meta}} ->
      relations = Enum.map(meta, &(&1.relation_id))
      set_last_read(relations, key)
    end)
  end

  defp set_last_read([], _user_id), do: :ok
  defp set_last_read(data, user_id), do: Phos.Folk.set_last_read(data, user_id)
end
