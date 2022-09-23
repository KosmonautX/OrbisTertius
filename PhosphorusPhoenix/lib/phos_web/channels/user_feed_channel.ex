defmodule PhosWeb.UserFeedChannel do
  use PhosWeb, :channel

  def join("userfeed:" <> id, _payload, socket) do
    if authorized?(socket, id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("feed", {:new, feed}, socket) do
    broadcast(socket, "feed", feed)
    {:noreply, socket}
  end

  def handle_in("ping", _, socket) do
    {:noreply, socket}
  end
end
