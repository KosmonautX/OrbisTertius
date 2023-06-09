defmodule PhosWeb.UserProfileLive.Show do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Action
  alias PhosWeb.Components.ScrollAlly
  alias PhosWeb.Components.ScrollOrb

  defguard is_uuid?(value)
           when is_bitstring(value) and
                  byte_size(value) == 36 and
                  binary_part(value, 8, 1) == "-" and
                  binary_part(value, 13, 1) == "-" and
                  binary_part(value, 18, 1) == "-" and
                  binary_part(value, 23, 1) == "-"

  @impl true
  def mount(
        %{"username" => id} = params,
        _session,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    # check if really subscribing
    if connected?(socket), do: Phos.PubSub.subscribe("folks")

    {:ok, user} = mount_user(id)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:current_user, current_user)
     |> assign_meta(user, params)
     |> assign(:parent_pid, socket.transport_pid)
     |> stream_assign(:orbs, Action.orbs_by_initiators([user.id], 1))
     |> stream_assign(:ally_list, ScrollAlly.check_more_ally(current_user, user.id, 1, 24))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event(
        "load-more",
        _,
        %{assigns: %{ally_list: allies_meta, orbs: orbs_meta, current_user: curr, user: user}} =
          socket
      ) do
    expected_ally_page = allies_meta.pagination.current + 1
    expected_orb_page = orbs_meta.pagination.current + 1

    newsocket =
      with orbs <- ScrollOrb.check_more_orb(user.id, expected_orb_page),
           allies <- ScrollAlly.check_more_ally(curr, user.id, expected_ally_page, 24) do
        load_more_streams(socket, %{orbs: %{data: orbs.data, meta: orbs.meta}}, %{
          allies: %{data: allies.data, meta: allies.meta}
        })
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
     |> push_patch(to: ~p"/user/#{socket.assigns.user.username}")}
  end

  defp mount_user(id) when is_uuid?(id) do
    case Users.find_user_by_id(id) do
      {:ok, %Users.User{} = user} -> {:ok, user}
      nil -> raise PhosWeb.ErrorLive.FourOFour, message: "User Not Found"
    end
  end

  defp mount_user(username) do
    case Users.get_user_by_username(username) do
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

  defp load_more_streams(socket, %{orbs: %{data: orbs, meta: orbs_meta}}, %{
         allies: %{data: allies, meta: allies_meta}
       }) do
    Enum.reduce(allies, socket, fn ally, acc -> stream_insert(acc, :ally_list, ally) end)
    |> then(&Enum.reduce(orbs, &1, fn orb, acc -> stream_insert(acc, :orbs, orb) end))
    |> assign(orbs: orbs_meta)
    |> assign(ally_list: allies_meta)
  end

  defp stream_assign(socket, key, %{data: data, meta: meta} = params) do
    socket
    |> stream(key, data)
    |> assign(key, meta)
  end
end
