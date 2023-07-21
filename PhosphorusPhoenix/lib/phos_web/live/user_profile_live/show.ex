defmodule PhosWeb.UserProfileLive.Show do
  use PhosWeb, :live_view
  alias Phos.Users
  alias Phos.Action
  alias PhosWeb.Components.ScrollAlly
  alias PhosWeb.Components.ScrollOrb

  @impl true
  def mount(
        %{"username" => id} = params,
        _session,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    # check if really subscribing
    if connected?(socket), do: Phos.PubSub.subscribe("folks")

    {:ok, user} = mount_user(id)

    allies = ScrollAlly.check_more_ally(current_user, user.id, 1, 24)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:current_user, current_user)
     |> assign_meta(user, params)
     |> assign(:parent_pid, socket.transport_pid)
     |> assign(:ally_count, allies.meta.pagination.total)
     |> stream_assign(:orbs, Action.orbs_by_initiators([user.id], 1))
     |> stream_assign(:ally_list, allies)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true

  def handle_event(
        "load-orbs",
        _,
        %{assigns: %{orbs: orbs_meta, current_user: curr, user: user}} =
          socket
      ) do
    expected_orb_page = orbs_meta.pagination.current + 1

    {:noreply, socket |> stream_assign(:orbs, ScrollOrb.check_more_orb(user.id, expected_orb_page))}
  end

  def handle_event(
    "load-relations",
    _,
    %{assigns: %{ally_list: allies_meta, current_user: curr, user: user}} = socket
  ) do
    expected_ally_page = allies_meta.pagination.current + 1

    {:noreply, socket |> stream_assign(:ally_list, ScrollAlly.check_more_ally(curr, user.id, expected_ally_page, 24)
    )}
  end

  def handle_event("show_ally", %{"ally" => ally_id}, %{assigns: %{current_user: curr}} = socket) do
    {:noreply,
     socket
     |> assign(:ally, Phos.Users.get_public_user(ally_id, curr && curr.id || nil))
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
        %Phoenix.Socket.Broadcast{topic: "folks", event: action, payload: root_id},
        %{assigns: %{current_user: user}} = socket
      )
      when action in ["add", "reject", "accept"] do
    %{initiator_id: init_id, acceptor_id: acc_id} = root = Phos.Folk.get_relation!(root_id)

    case init_id == user.id or acc_id == user.id do
      true ->
        send_update(PhosWeb.Component.AllyButton,
          id: "ally_component_infinite_scroll_#{acc_id}",
          root_id: root.id
        )

        {:noreply, put_flash(socket, :info, "Relation updated")}

      _ ->
        {:noreply, put_flash(socket, :info, "no change on relation")}
    end
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{topic: "folks", event: "delete", payload: {init_id, acc_id}},
        %{assigns: %{current_user: user}} = socket
      ) do
    case init_id == user.id or acc_id == user.id do
      true ->
        send_update(PhosWeb.Component.AllyButton,
          id: "user-information-card-ally",
          related_users: %{receiver_id: init_id, sender_id: user.id}
        )

        send_update(PhosWeb.Component.AllyButton,
          id: "user-information-card-ally-desktop",
          related_users: %{receiver_id: init_id, sender_id: user.id}
        )

        {:noreply, put_flash(socket, :error, "Ally request is deleted")}

      _ ->
        {:noreply, put_flash(socket, :info, "handle info not matched")}
    end
  end

  def handle_info("unredirect", socket) do
    {:noreply,
     socket
     |> assign(:redirect, nil)
     |> push_patch(to: ~p"/user/#{socket.assigns.user.username}")}
  end

  defp mount_user(id_or_username) do
    case Users.get_user(id_or_username) do
      %Users.User{} = user -> {:ok, user}
      nil -> raise PhosWeb.ErrorLive.FourOFour, message: "User Not Found"
    end
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(page_title: "Viewing Profile")
  end

  defp apply_action(socket, :edit, params) do
    if(socket.assigns.current_user.username == params["username"]) do
      socket
      |> assign(:page_title, "Updating Profile")
    else
      push_patch(socket, to: ~p"/user/#{params["username"]}")
    end
  end

  defp apply_action(socket, :allies, _params) do
    socket
    |> assign(page_title: "Viewing Allies")
  end

  defp assign_meta(socket, user, %{"bac" => _}) do
    Process.send_after(self(), "unredirect", 888)
    socket |> assign(:redirect, true) |> assign_meta(user)
  end

  defp assign_meta(socket, user, _), do: assign_meta(socket, user)

  defp assign_meta(socket, user) do
    assign(socket, :meta, %{
      author: user,
      mobile_redirect: "userland/others/" <> user.id,
      title: "@#{user.username}",
      description: user |> get_in([Access.key(:public_profile, %{}), Access.key(:bio, "-")]),
      type: "website",
      # TODO fetch from media
      image: Phos.Orbject.S3.get!("USR", user.id, "public/profile/lossless"),
      url: url(socket, ~p"/user/#{user.username}")
    })
  end

  # look to integrate Repo.Paginated.all() :meta

  defp stream_assign(socket, key, %{data: data, meta: meta}, opts \\ []) do
    socket
    |> stream(key, data, opts)
    |> assign(key, meta)
  end
end
