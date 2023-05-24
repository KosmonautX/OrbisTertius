defmodule PhosWeb.Admin.UserLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Users

  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    search = ""
    {:ok,
      assign(socket,
      users: Phos.Users.list_users(),
      search: ""
    )}
  end

  def handle_event("search",%{"_target" => [_a, search_term] = target} = search, socket ) do

    search_value = get_in(search, target)

    case search_term do
      "username" ->
        socket =
          assign(socket,
          search: search_value,
          users: Phos.Users.filter_user_by_username(search_value)
        )
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end

  end

  def handle_params(%{"username" => username} = params, _url, socket) do
    with %Users.User{} = user <- Users.get_user_by_username(username) do
      {:noreply,
        socket
        |> assign(:user, user)
        |> apply_action( socket.assigns.live_action, params)}
    else
      {:error,_} -> IO.inspect("FAIL")
      {:noreply, socket}
    end

  end

  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end


  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Viewing Users")
  end

  defp apply_action(socket, :edit, params) do
    socket
    |> assign(:page_title, "Updating Profile")
  end

end
