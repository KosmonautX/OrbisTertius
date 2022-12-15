defmodule PhosWeb.ReverieLive.Show do
  use PhosWeb, :live_view

  alias Phos.Message

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:reverie, Message.get_reverie!(id))}
  end

  defp page_title(:show), do: "Show Reverie"
  defp page_title(:edit), do: "Edit Reverie"
end
