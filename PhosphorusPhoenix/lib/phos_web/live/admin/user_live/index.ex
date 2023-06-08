defmodule PhosWeb.Admin.UserLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Users
  alias Phos.Leaderboard


  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    search = ""

    %{data: users, meta: user_meta} = Users.list_users(limit, page)

    {:ok,
      socket
      |> assign(limit: limit)
      |> assign(search: search)
      |> assign(admin: true)
      |> assign(user_meta: user_meta)
      |> assign(today: NaiveDateTime.utc_now())
      |> stream(:users, users)
    }
  end

  def handle_event("search",%{"_target" => [_a, search_term] = target} = search, %{assigns: %{limit: limit}} = socket) do

    search_value = get_in(search, target)
    %{data: users, meta: new_meta} = Users.filter_user_by_username(search_value, limit, 1)
    case search_term do
      "username" ->
      {:noreply,
        socket
        |> assign(search: search_value)
        |> assign(user_meta: new_meta)
        |> stream(:users, users, reset: true)
      }
      _ ->
        {:noreply, socket}
    end

  end

  def handle_event(
    "load-more",
    _,
    %{assigns: %{search: search, limit: limit, user_meta: %{pagination: pagination}}} = socket
    ) do
    expected_page = pagination.current + 1


    %{data: new_users, meta: new_meta} = Users.filter_user_by_username(search, limit, expected_page)

    {:noreply,
    socket
    |> assign(user_meta: new_meta)
    |> stream(:users, new_users)
  }

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
