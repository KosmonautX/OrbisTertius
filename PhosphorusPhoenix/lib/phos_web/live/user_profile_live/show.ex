defmodule PhosWeb.UserProfileLive.Show do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Action

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"username" => username} = params, _url, socket) do
    user = %{id: user_id} =
    Users.get_user_by_username(username)
    |> Map.put(:locations, ["Chennai", "Vandavasi"])
    {:noreply, socket
      |> assign(:params, params)
      |> assign(:user, user)
      |> assign_meta(user)
      |> assign(:orbs, Action.orbs_by_initiators([user_id], 1))
      |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_params(%{"user_id" => user_id} = params, _url, socket) do
    {:noreply, socket
      |> assign(:params, params)
      |> assign(:user, Users.get_user!(user_id))
      |> assign(:orbs, Action.get_active_orbs_by_initiator(user_id))
      |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Updating Profile")
  end

  defp assign_meta(socket, user) do
    assign(socket, :meta, %{
      title: "#{user.username} aka #{user.public_profile.public_name}",
      description: user.public_profile.bio,
      type: "website",
      image: Phos.Orbject.S3.get!("USR", user.id, "public/banner/lossless"),
      url: url(socket, ~p"/user/#{user.id}")
    })
  end

end
