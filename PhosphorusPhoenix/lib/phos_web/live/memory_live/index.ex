defmodule PhosWeb.MemoryLive.Index do
  use PhosWeb, :live_view

  alias Phos.Message
  alias Phos.Message.Memory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :memories, list_memories())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Memory")
    |> assign(:memory, Message.get_memory!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Memory")
    |> assign(:memory, %Memory{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Memories")
    |> assign(:memory, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    memory = Message.get_memory!(id)
    {:ok, _} = Message.delete_memory(memory)

    {:noreply, assign(socket, :memories, list_memories())}
  end

  defp list_memories do
    Message.list_memories()
  end
end
