defmodule PhosWeb.UserProfileLive.Index do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Action

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"username" => username} = params, _url, socket) do
    %{id: user_id} = Users.get_user_by_username(username)
    {:noreply, socket
      |> assign(:params, params)
      |> assign(:user, Users.get_user!(user_id))
      |> assign(:orbs, Action.get_active_orbs_by_initiator(user_id))
      |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_params(%{"user_id" => user_id} = params, _url, socket) do
    {:noreply, socket
      |> assign(:params, params)
      |> assign(:user, Users.get_user!(user_id))
      |> assign(:orbs, Action.get_active_orbs_by_initiator(user_id))
      |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "User Profile")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "User Profile")
  end

  defp apply_action(socket, :sethome, _params) do
    socket
    |> assign(:page_title, "Set Home Location")
    |> assign(:setloc, :home)
  end
end
