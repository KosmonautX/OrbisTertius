defmodule PhosWeb.UserProfileLive.Show do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Action

  @impl true
  def mount(%{"username" => username} = params, _session, %{assigns: %{current_user: current_user}} = socket) do
    with %Users.User{} = user <- Users.get_user_by_username(username) do
    Phos.PubSub.subscribe("folks")

    {:ok,
     socket
     |> assign(:user, user)
     |> assign_meta(user, params)
     |> assign(orb_page: 1)
     |> assign(ally_page: 1), temporary_assigns: [orbs: Action.orbs_by_initiators([user.id], 1).data,
       allies: ally_list(current_user, user)]}

    else
      nil -> raise PhosWeb.ErrorLive.FourOFour, message: "User Not Found"
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
      {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event(
        "load-more",
        %{"archetype" => "rel"},
        %{assigns: %{current_user: user, ally_page: page, user: friend}} = socket
      ) do
    expected_page = page + 1

    case ally_list(user, friend, expected_page) do
      [_|_] = allies -> {:noreply,
      assign(socket,
        page: expected_page,
        allies: allies)}
      _ -> {:noreply, socket}
    end
   end

  def handle_event("load-more", %{"archetype" => "orb"}, %{assigns: %{orb_page: page, user: user}} = socket) do
    expected_page = page + 1
    case Action.orbs_by_initiators([user.id], expected_page).data do
      [_|_] = orbs -> {:noreply, assign(socket, page: expected_page, orbs: orbs)}
      _ -> {:noreply, socket}
    end
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
     |> push_patch(to: ~p"/user/#{socket.assigns.user.username}")
    }
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

  defp ally_list(current_user, friend, page \\ 1)

  defp ally_list(%Phos.Users.User{id: id} = _current_user, friend, page),
    do: ally_list(id, friend, page)

  defp ally_list(current_user, %Phos.Users.User{id: id} = _friend, page),
    do: ally_list(current_user, id, page)

  defp ally_list(current_user_id, friend_id, page)
       when is_bitstring(current_user_id) and is_bitstring(friend_id) do
    case friend_id == current_user_id do
      false ->
        Phos.Folk.friends({friend_id, current_user_id}, page) |> Map.get(:data, [])

      _ ->
        Phos.Folk.friends(current_user_id, page)
        |> Map.get(:data, [])
        |> Enum.map(&Map.get(&1, :friend))
    end
  end

  defp ally_list(nil, friend_id, page),
    do:
      Phos.Folk.friends(friend_id, page) |> Map.get(:data, []) |> Enum.map(&Map.get(&1, :friend))

  defp ally_list(_, _, _), do: []
end
