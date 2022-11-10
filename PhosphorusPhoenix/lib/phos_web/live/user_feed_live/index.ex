defmodule PhosWeb.UserFeedLive.Index do
  use PhosWeb, :live_view

  def mount(_params, %{"user_token" => token} = _session, %{assigns: %{current_user: user}} = socket) do
    PhosWeb.Endpoint.subscribe("userfeed:#{user.id}", token: token)
    {:ok, socket}
  end

  def handle_params(_params, _url, %{assigns: %{current_user: user}} = socket) do
    {:noreply, socket
      |> assign(:feeds, Phos.Folk.feeds(user.id))}
  end

  def handle_info({Phos.PubSub, {:feeds, "new"}, orb}, %{assigns: %{feeds: feeds}} = socket) do
    {:noreply, assign(socket, :feeds, [orb | feeds])}
  end
end
