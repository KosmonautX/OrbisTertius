defmodule PhosWeb.MemoryLive.Index do
  use PhosWeb, :live_view

  alias Phos.Message
  alias Phos.Message.Memory
  alias PhosWeb.Presence

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    Phos.PubSub.subscribe("memory:user:#{user.id}")
    %{
      data: search_memories,
      meta: metadata,
    } = memories_by_user(user)

    {:ok,
     socket
     |> assign(usersearch: "", search_memories: map_last_memory(search_memories), metadata: metadata)}
  end

  @impl true
  def handle_params(params, _url, %{assigns: assigns} = socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: your}} = socket, :show, %{"username" => username})
    when your.username == username, do: push_navigate(socket, to: ~p"/memories")

  defp apply_action(%{assigns: %{current_user: your}} = socket, :show, %{"username" => username}) do
    {%{data: mems, meta: meta}, rel_id} =
      case user = Phos.Users.get_public_user_by_username(username, your.id) do
        %{self_relation: nil} -> {%{meta: %{}, data: []}, nil}
        %{self_relation: rel} -> {list_memories(user, rel.id), rel.id}
      end

    send_update(PhosWeb.MemoryLive.FormComponent, id: :new_on_dekstop, memory: %Memory{})
    send_update(PhosWeb.MemoryLive.FormComponent, id: :new_on_mobile, memory: %Memory{})
    spawn(fn -> friend_online_status(socket, user, relation: rel_id) end)

    socket
    |> assign(:page_title, "Chatting with @" <> username)
    |> assign(:memory, %Memory{})
    |> assign(:relation_id, rel_id)
    |> assign(user: user, message_cursor: Map.get(meta, :pagination, %{}) |> Map.get(:cursor))
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
    IO.inspect("INDEX")
    spawn(fn -> friend_online_status(socket, user) end)
    socket
    |> assign(:page_title, "Listing Memories")
    |> assign(:memory, nil)
    |> assign(:user, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    memory = Message.get_memory!(id)
    {:ok, _} = Message.delete_memory(memory)

    {:noreply, assign(socket, :memories, [])}
  end

  @impl true
  def handle_event("load-more", _, socket) do
    {:noreply, list_more_mesage(socket)}
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
  def handle_info({:run_search, usersearch}, %{assigns: %{current_user: user}} = socket) do
    %{data: data, meta: meta} = Message.search_message_by_user(user, usersearch)

    {:noreply, 
      assign(socket, 
        search_memories: Enum.map(data, &(&1.last_memory)) |> Enum.reverse(),
        user_cursor: Map.get(meta.pagination, :cursor))}
  end

  def handle_info({Phos.PubSub, {:memory, "formation"}, %{rel_subject_id: rel_id} = data}, %{assigns: %{current_user: user, memories: memories}} = socket) do
    %{data: search_memories, meta: _meta} = memories_by_user(user)
    {:noreply, assign(socket, memories: memories ++ [data], search_memories: map_last_memory(search_memories), memory: %Memory{})}
  end

  def handle_info(_data, socket) do
    {:noreply, socket}
  end

  defp list_more_mesage(%{assigns: %{message_cursor: cursor, current_user: user, memories: [memory | _tail] = memories}} = socket) when not is_nil(cursor) do
    time = DateTime.from_unix!(cursor, :millisecond)
    %{meta: %{pagination: pagination}, data: data} = list_memories(user, memory.rel_subject_id, filter: time)
    new_data = Kernel.++(data, memories) |> Enum.sort(&(DateTime.compare(&1.inserted_at, &2.inserted_at) == :lt))

    socket
    |> assign(message_cursor: Map.get(pagination, :cursor, nil))
    |> assign(memories: new_data)
  end
  defp list_more_mesage(socket), do: socket

  defp list_memories(user, relation_id, opts \\ [])
  defp list_memories(%{id: user_id} = _current_user, relation_id, opts), do: list_memories(user_id, relation_id, opts)
  defp list_memories(user_id, relation_id, opts) do
    Message.list_messages_by_relation({relation_id, user_id}, opts)
  end

  defp memories_by_user(user, opts \\ []) do
    Message.list_messages_by_user(user, opts)
  end

  defp map_last_memory(relationships) do
    Enum.map(relationships, &(&1.last_memory)) |> Enum.reverse()
  end
end
