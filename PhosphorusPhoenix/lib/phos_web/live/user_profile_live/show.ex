defmodule PhosWeb.UserProfileLive.Show do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Action

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page: 1), temporary_assigns: [ally_list: []]}
  end

  @impl true
  def handle_params(%{"username" => username} = params, _url, %{assigns: %{current_user: current_user} = assigns} = socket) do
    with %Users.User{} = user <- Users.get_user_by_username(username) do
    {:noreply, socket
      |> assign(:params, params)
      |> assign(:user, user)
      |> assign(:ally_list, ally_list(current_user, user))
      |> assign_meta(user)
      |> assign(:orbs, Action.orbs_by_initiators([user.id], 1).data)
      |> apply_action(socket.assigns.live_action, params)}
    else
      nil -> raise PhosWeb.ErrorLive, message: "User Not Found"
    end
  end

  def handle_params(%{"user_id" => user_id} = params, _url, %{assings: %{current_user: current_user}} = socket) do
    user = Users.get_user!(user_id)
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:user, user)
     |> assign(:ally_list, ally_list(current_user, user))
     |> assign(:orbs, Action.get_active_orbs_by_initiator(user_id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("load-more", _, %{assigns: %{current_user: user, page: page, ally_list: ally_list, user: friend} = assigns} = socket) do
    expected_page = page + 1
    {:noreply, assign(socket, page: expected_page, ally_list: ally_list ++ ally_list(user, friend, expected_page))}
  end

  @impl true
  def handle_event("load-more", _, %{assigns: %{current_user: user}} = socket) when is_nil(user), do: {:noreply, socket}

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(page_title: "Viewing Profile")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Updating Profile")
  end

  defp apply_action(socket, :allies, _params) do
    socket
    |> assign(page_title: "Viewing Allies")
  end

  defp assign_meta(socket, user) do
    assign(socket, :meta, %{
      title: "@#{user.username}",
      description: user |> get_in([Access.key(:public_profile, %{}), Access.key(:bio, "-")]),
      type: "website",
      image: Phos.Orbject.S3.get!("USR", user.id, "public/banner/lossless"), #TODO fetch from media
      url: url(socket, ~p"/user/#{user.id}")
    })
  end

  defp ally_list(current_user, friend, page \\ 1)
  defp ally_list(%Phos.Users.User{id: id} = _current_user, friend, page), do: ally_list(id, friend, page)
  defp ally_list(current_user, %Phos.Users.User{id: id} = _friend, page), do: ally_list(current_user, id, page)
  defp ally_list(current_user_id, friend_id, page) when is_bitstring(current_user_id) and is_bitstring(friend_id) do
    case friend_id == current_user_id do
      false -> Phos.Folk.friends({friend_id, current_user_id}, page) |> Map.get(:data, [])
      _ ->
        Phos.Folk.friends(current_user_id, page)
        |> Map.get(:data, [])
        |> Enum.map(&Map.get(&1, :friend))
    end
  end
  defp ally_list(_, _, _), do: []
end
