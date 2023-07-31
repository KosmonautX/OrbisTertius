defmodule PhosWeb.MemoryLive.Index do
  use PhosWeb, :live_view

  alias Phos.Message
  alias Phos.Message.Memory

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) when not is_nil(user) do
    Phos.PubSub.subscribe("memory:user:#{user.id}")
    {:ok, init_relations(socket)}
  end

  def mount(%{token: token} = params, _session, %{assigns: %{current_user: user}} = socket) when is_nil(user) do
    with {:ok, claims} <- Auth.validate_user(token),
        user = Users.get_user(claims["user_id"]) do
      Phos.PubSub.subscribe("memory:user:#{user.id}")
      assign(socket, :current_user, user)
      {:ok, init_relations(socket)}
    else
      _ -> push_navigate(socket, to: "/users/log_in")
    end
  end

  @impl true
  def handle_params(params, _url, %{assigns: assigns} = socket) do
    {:noreply, apply_action(socket, assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: your}} = socket, :show, %{"username" => username})
       when your.username == username,
       do: push_navigate(socket, to: ~p"/memories")

  defp apply_action(%{assigns: %{current_user: your}} = socket, :show, %{"username" => username}) do
    {%{data: mems, meta: meta}, rel_id} =
      case user = Phos.Users.get_public_user_by_username(username, your.id) do
        %{self_relation: nil} -> {%{meta: %{}, data: []}, nil}
        %{self_relation: rel} -> {list_memories(user, rel.id, limit: 24), rel.id}
      end

    send_update(PhosWeb.MemoryLive.FormComponent, id: :new_on_desktop, memory: %Memory{})

    PhosWeb.Presence.track(self(), "memory:user:#{your.id}", "last_read", %{rel_id: rel_id})

    socket
    |> assign(:page_title, "Chatting with @" <> username)
    |> assign(:memory, %Memory{})
    |> assign(:relation_id, rel_id)
    |> assign(user: user, message_cursor: Map.get(meta, :pagination, %{}) |> Map.get(:cursor))
    |> stream(:message_memories, mems |> Enum.reverse(), reset: true)
    |> assign(:message_meta, meta)
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

  defp apply_action(socket, :media, %{"id" => id} = _params) do
    memory = Message.get_memory!(id)

    media =
      Phos.Orbject.S3.get_all!("MEM", memory.id, "public/profile")
      |> (fn
            nil ->
              []

            media ->
              for {path, url} <- media do
                %Phos.Orbject.Structure.Media{
                  ext: MIME.from_path(path),
                  path: path,
                  url: url,
                  resolution:
                    path |> String.split(".") |> hd() |> String.split("/") |> List.last()
                }
              end
          end).()
      |> Enum.filter(fn m -> m.resolution == "lossless" end)

    socket
    |> assign(:page_title, "Memory Media")
    |> assign(:relation_id, memory.rel_subject_id)
    |> assign(:memory, memory)
    |> assign(:media, media)
    |> assign_new(:user, fn -> memory.user_source end)
    |> assign(:memories, [])
    |> assign(:message_cursor, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    memory = Message.get_memory!(id)
    {:ok, _} = Message.delete_memory(memory)

    {:noreply, assign(socket, :memories, [])}
  end

  @impl true
  def handle_event("load-messages", _, socket), do: {:noreply, list_more_message(socket)}

  def handle_event("load-relations", _, socket), do: {:noreply, list_more_chats(socket)}


  def handle_event("search", params, socket) do
    {:noreply, socket |> search_memories(params)}
  end

  def handle_event("show_ally", %{"ally" => ally_id}, %{assigns: %{current_user: curr}} = socket) do
    {:noreply,
     socket
     |> assign(:ally, Phos.Users.get_public_user(ally_id, curr.id))
     |> assign(:live_action, :ally)}
  end

  def handle_event("hide_ally", _, socket) do
    {:noreply,
     socket
     |> assign(:ally, nil)
     |> assign(:live_action, :show)}
  end

  @impl true

  def handle_info(
        {Phos.PubSub, {:memory, "formation"}, %{rel_subject_id: _rel_id} = data},
        %{assigns: %{current_user: user}} = socket
      ) do
    %{data: relation_memories, meta: _meta} = memories_by_user(user)

    {:noreply,
     socket
     |> assign(:memory, %Memory{})
     |> stream(:message_memories, [data])
     |> stream(:relation_memories, relation_memories, reset: true)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp init_relations(%{assigns: %{current_user: user}} = socket) do
    %{
      data: relation_memories,
      meta: %{pagination: %{cursor: cursor}} = metadata
    }
    = memories_by_user(user, limit: 12)

    socket
    |> assign(
      usersearch: "",
      media: [],
      relation_meta: metadata,
      relation_cursor: cursor
    )
    |> stream(:relation_memories, relation_memories)
  end

  defp list_more_message(
          %{
           assigns: %{
             message_cursor: cursor,
             current_user: user,
             relation_id: rel_id,
             message_meta: %{pagination: %{downstream: true}}
           }
         } = socket
       )
       when not is_nil(cursor) do
    time = DateTime.from_unix!(cursor, :second)

    %{data: data, meta: %{pagination: %{cursor: new_cursor}} = metadata} =
      list_memories(user, rel_id, filter: time, limit: 12)

    socket
    |> assign(message_cursor: new_cursor)
    |> assign(message_meta: metadata)
    |> stream(:message_memories, data, at: 0)
  end


  defp list_more_message(socket), do: socket

  defp list_more_chats(
         %{
           assigns: %{
             current_user: user,
             relation_cursor: cursor,
             relation_meta: %{pagination: %{downstream: true}}
           }
         } = socket
       )
       when not is_nil(cursor) do
    %{
      data: relation_memories,
      meta: %{pagination: %{cursor: new_cursor}} = metadata
    } = memories_by_user(user, filter: NaiveDateTime.add(~N[1970-01-01 00:00:00], cursor, :second))

    IO.inspect(cursor |> DateTime.from_unix(:second), label: "load-more")

    socket
    |> stream(:relation_memories, relation_memories)
    |> assign(:relation_cursor, new_cursor )
    |> assign(:relation_meta, metadata)
  end

  defp list_more_chats(socket), do: socket

  defp list_memories(user, relation_id, opts \\ [])

  defp list_memories(%{id: user_id} = _current_user, relation_id, opts),
    do: list_memories(user_id, relation_id, opts)

  defp list_memories(user_id, relation_id, opts) do
    Message.list_messages_by_relation({relation_id, user_id}, opts)
  end

  defp memories_by_user(user, opts \\ []) do
    Phos.Folk.last_messages_by_relation(user.id, opts)
  end

  defp search_memories(%{assigns: %{current_user: user}} = socket, %{"usersearch" => usersearch}) do
    %{data: relation_memories, meta: %{pagination: %{cursor: cursor}} = meta} =  Phos.Folk.search_last_messages(user.id, usersearch, [])
    socket
    |> assign(relation_meta: meta)
    |> assign(relation_cursor: cursor)
    |> stream(:relation_memories, relation_memories, reset: true)
  end

  defp get_date_time(time, timezone) do
    time
    |> DateTime.from_naive!("UTC")
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{0D}-{0M}-{YYYY},{h12}:{m} {AM}")
    |> elem(1)
  end
end
