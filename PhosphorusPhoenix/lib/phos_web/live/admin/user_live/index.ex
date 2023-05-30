defmodule PhosWeb.Admin.UserLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Repo
  alias Phos.Users

  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    search = ""
    {:ok,
      socket
      |> assign(users: Users.list_users(limit))
      |> assign(search: "")
      |> assign(admin: true)
      |> assign(today: NaiveDateTime.utc_now())
    }
  end

  def handle_event("search",%{"_target" => [_a, search_term] = target} = search, socket ) do

    search_value = get_in(search, target)

    case search_term do
      "username" ->
      {:noreply,
        socket
        |> assign(search: search_value)
        |> assign(users: Phos.Users.filter_user_by_username(search_value))
      }
      _ ->
        {:noreply, socket}
    end

  end

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
