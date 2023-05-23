defmodule PhosWeb.Admin.UserLive.Index do
  use PhosWeb, :admin_view

  import Phos.Users

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
end
