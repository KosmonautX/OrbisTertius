defmodule PhosWeb.ReverieLive.Index do
  use PhosWeb, :live_view

  alias Phos.Message
  alias Phos.Message.Reverie

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :reveries, list_reveries())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Reverie")
    |> assign(:reverie, Message.get_reverie!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Reverie")
    |> assign(:reverie, %Reverie{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Reveries")
    |> assign(:reverie, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    reverie = Message.get_reverie!(id)
    {:ok, _} = Message.delete_reverie(reverie)

    {:noreply, assign(socket, :reveries, list_reveries())}
  end

  defp list_reveries do
    Message.list_reveries()
  end
end
