defmodule PhosWeb.UserProfileLive.Show do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Action


  defguard is_uuid?(value)
  when is_bitstring(value)
  and byte_size(value) == 36
  and binary_part(value, 8, 1) == "-"
  and binary_part(value, 13, 1) == "-"
  and binary_part(value, 18, 1) == "-"
  and binary_part(value, 23, 1) == "-"

  @impl true
  def mount(%{"username" => id} = params, _session, %{assigns: %{current_user: current_user}} = socket) when is_uuid?(id) do
    with {:ok, %Users.User{} = user} <- Users.find_user_by_id(id) do
    Phos.PubSub.subscribe("folks")

    {:ok,
    socket
     |> assign(:user, user)
     |> assign(:current_user, current_user)
     |> assign_meta(user, params)
     |> assign(orb_page: 1)
     |> assign(ally_page: 1)
     |> assign(end_of_orb?: false)
     |> assign(end_of_ally?: false)
     |> assign(:parent_pid, socket.transport_pid)
     |> stream(:orbs, Action.orbs_by_initiators([user.id], 1).data)
     |> stream(:ally_list, ally_list(current_user, user))
    }
    else
      nil -> raise PhosWeb.ErrorLive.FourOFour, message: "User Not Found"
    end
  end


  def mount(%{"username" => username} = params, _session, %{assigns: %{current_user: current_user}} = socket) do
    with %Users.User{} = user <- Users.get_user_by_username(username) do
    Phos.PubSub.subscribe("folks")

    {:ok,
    socket
     |> assign(:user, user)
     |> assign(:current_user, current_user)
     |> assign_meta(user, params)
     |> assign(orb_page: 1)
     |> assign(ally_page: 1)
     |> assign(end_of_orb?: false)
     |> assign(end_of_ally?: false)
     |> assign(:parent_pid, socket.transport_pid)
     |> stream(:orbs, Action.orbs_by_initiators([user.id], 1).data)
     |> stream(:ally_list, ally_list(current_user, user))
    }
    else
      nil -> raise PhosWeb.ErrorLive.FourOFour, message: "User Not Found"
  end
    end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("load-more", %{"archetype" => "ally"}, %{assigns: %{ally_page: ally_page, current_user: curr, user: user}} = socket) do
    expected_ally_page = ally_page + 1

    newsocket =
      case check_more_ally(curr.id, user.id, expected_ally_page) do
        {:ok, allies} ->
          Enum.reduce(allies, socket, fn ally, acc -> stream_insert(acc, :ally_list, ally) end)
          |> assign(ally_page: expected_ally_page)
        {:error, _} ->
          assign(socket, end_of_ally?: true)
      end
    {:noreply, newsocket}
  end

  def handle_event("load-more", %{"archetype" => "orb"}, %{assigns: %{orb_page: orb_page, user: user}} = socket) do
    expected_orb_page = orb_page + 1

    newsocket =
      case check_more_orb(user.id, expected_orb_page) do
        {:ok, orbs} ->
          Enum.reduce(orbs, socket, fn orb, acc -> stream_insert(acc, :orbs, orb) end)
          |> assign(orb_page: expected_orb_page)
        {:error, _} ->
          assign(socket, end_of_orb?: true)
      end
      {:noreply, newsocket}
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

  defp check_more_ally(currid, userid, expected_ally_page) do
    case ally_list(currid, userid, expected_ally_page) do
      [_|_] = allies -> {:ok, allies}
      _ -> {:error, %{message: "no ally"}}
    end
  end

  def check_more_orb(userid, expected_orb_page) do
    case Action.orbs_by_initiators([userid], expected_orb_page).data do
      [_|_] = orbs -> {:ok, orbs}
      _ -> {:error, %{message: "no orb"}}
    end
  end
end
