defmodule PhosWeb.OrbLive.Index do
  use PhosWeb, :live_view

  alias Phos.Action
  alias Phos.Action.Orb

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :orbs, list_orbs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Orb")
    |> assign(:orb, Action.get_orb!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Orb")
    |> assign(:orb, %Orb{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Orbs")
    |> assign(:orb, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    orb = Action.get_orb!(id)
    {:ok, _} = Action.delete_orb(orb)

    {:noreply, assign(socket, :orbs, list_orbs())}
  end

  defp list_orbs do
    Action.list_orbs()
  end
end
