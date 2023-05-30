defmodule PhosWeb.Admin.UserLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Users

  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    search = ""
   {:ok,
      assign(socket,
      users: Users.list_users(limit),
      search: "",
      admin: true
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

  # def handle_params(%{"page" => page} = params, _url, socket) do
  #   dbg
  # end
  def handle_params(%{"id" => id} = params, _url, socket) do
    with %Users.User{} = user <- Users.get_user!(id) do
      {:noreply,
        socket
        |> assign(:user, user)
        |> apply_action( socket.assigns.live_action, params)}
    else
      {:error,_} -> {:noreply, socket}
    end

  end

  def handle_params(_, _, socket) do
    {:noreply, socket}
  end


  defp apply_action(socket, :index, _) do
    socket
    |> assign(:page_title, "Viewing Users")
  end

  defp apply_action(socket, :edit, _) do
    socket
    |> assign(:page_title, "Updating Profile")
  end

end
