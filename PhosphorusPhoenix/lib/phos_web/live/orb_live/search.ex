defmodule PhosWeb.OrbLive.Search do
  use PhosWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"q" => query}, _url, socket) do
    {:noreply, assign(socket, search_value: query, orbs: Phos.Action.search(query))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, search_value: "", orbs: [])}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(orbs: Phos.Action.search(query), search_value: query)}
  end

end
