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

  def handle_metas("memory:user:" <> _user_id, %{leaves: leaves, joins: _joins}, _presence, state) do
    # TODO: need to implement
    Enum.reduce(leaves, [], fn {key, %{metas: metas}}, acc ->
      [
        Enum.reject(metas, fn m ->
          Map.get(m, :relation_id)
          |> Kernel.is_nil()
        end)
        |> Enum.map(&Map.put(&1, :user_id, key))
      | acc]
    end)
    |> List.flatten()
    |> Enum.filter(&(&1.foreign))
    |> Enum.map(fn %{user_id: user_id, relation_id: rel_id} -> set_last_read(rel_id, user_id) end)

    {:ok, state}
  end
  def handle_metas(_topic, _gates, _presence, state), do: {:ok, state}

  defp set_last_read([], _user_id), do: :ok
  defp set_last_read(data, user_id), do: Phos.Folk.set_last_read(data, user_id)
end
