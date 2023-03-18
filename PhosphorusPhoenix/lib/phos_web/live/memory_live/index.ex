defmodule PhosWeb.MemoryLive.Index do
  use PhosWeb, :live_view

  alias Phos.Message
  alias Phos.Message.Memory

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    Phos.PubSub.subscribe("memory:user:#{user.id}")
    mems = list_memories()

    {:ok,
     socket
     |> assign(:memories, mems)
     |> assign(:usersearch, "")
     |> assign(:search_memories, mems)
     |> assign(:page, 1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: your}} = socket, :show, %{"username" => username})
    when your.username == username, do: push_navigate(socket, to: ~p"/memories")

  defp apply_action(%{assigns: %{current_user: your}} = socket, :show, %{"username" => username}) do
    mems =
      case user = Phos.Users.get_public_user_by_username(username, your.id) do
        %{self_relation: nil} -> []
        %{self_relation: rel} -> 
          Message.list_messages_by_relation({rel.id, your.id}, 1).data
      end

    send_update(PhosWeb.MemoryLive.FormComponent, id: :new_on_dekstop, memory: %Memory{})
    send_update(PhosWeb.MemoryLive.FormComponent, id: :new_on_mobile, memory: %Memory{})

    socket
    |> assign(:page_title, "Chatting with @" <> username)
    |> assign(:memory, %Memory{})
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

  defp apply_action(%{assigns: %{current_user: user}} = socket, :index, _params) do
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

  @impl true
  def handle_info({:run_search, usersearch}, socket) do
    socket =
      assign(socket,
      search_memories: Message.search_by_username(usersearch)
      )

    {:noreply, socket}
  end

  def handle_info({Phos.PubSub, {:memory, "formation"}, _data}, socket) do
    mems = list_memories()
    {:noreply, assign(socket, memories: mems, search_memories: mems, memory: %Memory{})}
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
