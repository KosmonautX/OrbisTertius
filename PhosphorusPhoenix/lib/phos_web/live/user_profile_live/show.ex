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
  def handle_params(%{"username" => username} = params, _url, socket) do
    with %Users.User{} = user <- Users.get_user_by_username(username) do
    {:noreply, socket
      |> assign(:params, params)
      |> assign(:user, user)
      |> assign_meta(user)
      |> assign(:orbs, Action.orbs_by_initiators([user.id], 1).data)
      |> apply_action(socket.assigns.live_action, params)}
    else
      nil -> raise PhosWeb.ErrorLive, message: "User Not Found"
    end
  end

  def handle_params(%{"user_id" => user_id} = params, _url, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:user, Users.get_user!(user_id))
     |> assign(:orbs, Action.get_active_orbs_by_initiator(user_id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> get_ally()}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Viewing Profile")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Updating Profile")
  end

  defp apply_action(socket, :allies, _params) do
    socket
    |> assign(:page_title, "Viewing Allies")
  end

  defp assign_meta(socket, user) do
    assign(socket, :meta, %{
      title: "@#{user.username}",
      description: user |> get_in([Access.key(:public_profile, %{}), Access.key(:bio, "-")]),
      type: "website",
      image: Phos.Orbject.S3.get!("USR", user.id, "public/banner/lossless"),
      url: url(socket, ~p"/user/#{user.id}")
    })
  end

  defp ally_list do
    Phos.Users.list_users(5)
    |> Enum.shuffle()
  end

  defp get_ally(%{assigns: %{page: page}} = socket) do
    socket
    |> assign(page: page)
    |> assign(ally_list: socket.assigns.ally_list ++ ally_list())
  end

end
