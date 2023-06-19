defmodule PhosWeb.Admin.UserLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Users
  alias Phos.Leaderboard


  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    search = ""

    %{data: users, meta: meta} = Users.filter_user_by_username(search, limit, page)
    {:ok,
      socket
      |> assign(search: search)
      |> assign(limit: limit)
      |> assign(admin: true)
      |> assign(user_meta: meta )
      |> assign(today: NaiveDateTime.utc_now())
      |> stream(:users, users)
    }
  end

  def handle_params(%{"id" => id} = params, _url, socket) do

    with %Users.User{} = user <- Users.get_user!(id) do
      {:noreply,
        socket
        |> assign(:user, user)
        |> apply_action(socket.assigns.live_action, params)
      }
    else
      {:error,_} -> {:noreply, socket}
    end

  end

  def handle_params(%{"search" => %{"username" => search_value}} = params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def handle_event("change", params, socket) do
    {:noreply, apply_action(socket, :index, params)}
  end

  def handle_event(
    "load-more",
    params,
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

  defp apply_action(socket, :index, %{"search" => %{"username" => search_value}}) do
    %{data: users, meta: meta} = Users.filter_user_by_username(search_value, socket.assigns.limit, 1)
    socket
    |> assign(:page_title, "Viewing Users")
    |> assign(:user_meta, meta)
    |> assign(:search, search_value)
    |> stream(:users, users, reset: true)
  end

  defp apply_action(socket, :edit, _) do
    socket
    |> assign(:page_title, "Updating Profile")
  end

end
