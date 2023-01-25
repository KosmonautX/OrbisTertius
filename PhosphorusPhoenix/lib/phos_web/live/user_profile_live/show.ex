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
    user =
      %{id: user_id} =
      Users.get_user_by_username(username)
      |> Map.put(:traits, ["frontend_dev", "farmergirl", "noseafood", "doglover", "tailwind"])
      |> Map.put(:locations, ["Chennai", "Vandavasi"])

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:user, user)
     |> assign(:orbs, Action.get_active_orbs_by_initiator(user_id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_params(%{"user_id" => user_id} = params, _url, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:user, Users.get_user!(user_id))
     |> assign(:orbs, Action.get_active_orbs_by_initiator(user_id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> get_ally()}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "User Profile")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit User Profile")
  end

  defp apply_action(socket, :sethome, _params) do
    socket
    |> assign(:page_title, "Set Home Location")
    |> assign(:setloc, :home)
  end

  defp ally_list do
    Phos.Users.list_users()
    # |> List.duplicate(10)
    # |> :lists.concat()
    |> Enum.shuffle()
  end

  defp get_ally(%{assigns: %{page: page}} = socket) do
    socket
    |> assign(page: page)
    |> assign(ally_list: socket.assigns.ally_list ++ ally_list())
  end
end
