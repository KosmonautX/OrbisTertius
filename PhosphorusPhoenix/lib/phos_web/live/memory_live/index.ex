defmodule PhosWeb.MemoryLive.Index do
  use PhosWeb, :live_view

  alias Phos.Message
  alias Phos.Message.Memory

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:memories, list_memories())
     |> assign(:usersearch, "")
     |> assign(:search_memories, list_memories())
     |> assign(:page, 1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: your}} = socket, :show, %{"username" => username}) do
    mems =
      case user = Phos.Users.get_public_user_by_username(username, your.id) do
        %{self_relation: nil} -> []
        %{self_relation: rel} -> 
          Phos.PubSub.subscribe("memory:rel:#{rel.id}")
          Message.list_messages_by_relation({rel.id, your.id}, 1).data
      end

    socket
    |> assign(:page_title, "Chatting with @" <> username)
    |> assign(:memory, nil)
    |> assign(:user, user)
    |> assign(:memories, mems)
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
    |> assign(:user, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Memories")
    |> assign(:memory, nil)
    |> assign(:user, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    memory = Message.get_memory!(id)
    {:ok, _} = Message.delete_memory(memory)

    {:noreply, assign(socket, :memories, list_memories())}
  end

  @impl true
  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply,
     assign(socket, page: assigns.page + 1)
     |> list_more_mesage()}
  end

  def handle_event("search", %{"usersearch" => usersearch}, socket) do
    send(self(), {:run_search, usersearch})

    socket =
      assign(socket,
        usersearch: usersearch,
        search_memories: []
      )

    {:noreply, socket}
  end

  def handle_info({:run_search, usersearch}, socket) do
    socket =
      assign(socket,
      search_memories: Message.search_by_username(usersearch)
      )

    {:noreply, socket}
  end

  def handle_info({Phos.PubSub, "new_message", _memory}, socket) do
    {:noreply,
      socket
      |> assign(:memories, list_memories())
      |> assign(:search_memories, list_memories())}
  end

  defp list_more_mesage(%{assigns: %{page: page}} = socket) do
    socket
    |> assign(page: page)
    |> assign(memories: list_memories())
  end

  defp list_memories do
    Message.list_memories()
  end
end
