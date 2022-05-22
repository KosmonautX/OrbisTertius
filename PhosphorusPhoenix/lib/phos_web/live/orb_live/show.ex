defmodule PhosWeb.OrbLive.Show do
  use PhosWeb, :live_view

  alias Phos.Action

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:orb, Action.get_orb!(id))}
  end

  defp page_title(:show), do: "Show Orb"
  defp page_title(:edit), do: "Edit Orb"
end
