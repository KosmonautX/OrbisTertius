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

  def handle_metas(_topic, %{leaves: leaves}, _presence, state) do
    handle_absence(leaves)

    {:ok, state}
  end

  defp handle_absence(leaves) do
    Enum.map(leaves, fn {_key, %{metas: meta}} ->
      Enum.map(meta, &(&1.relation_id))
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> set_last_read()
  end

  defp set_last_read([]), do: :ok
  defp set_last_read(data), do: Phos.Folk.set_last_read(data)
end
