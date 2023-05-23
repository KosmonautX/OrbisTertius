defmodule PhosWeb.Admin.UserLive.Index do
  use PhosWeb, :admin_view

  import Phos.Users

  def mount(_params, _session, socket) do
    limit = 20
    page = 1
    search = ""
    # %{data: orbs, meta: meta} = filter_by_traits("", limit: limit, page: page)S

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
    # if not is_nil(search_value) && String.length(search_value) > 4 do
    #   case search_term do
    #     "username" ->
    #       socket =
    #       assign(socket,
    #       search: search_value,
    #       users: [Phos.Users.get_user_by_username("faez1")]
    #       )
    #       {:ok, socket}

    #     # "location" ->

    #     _ ->
    #       assign(socket,
    #       search: search_value)
    #   end
    # else

    #   {:noreply, socket}
    # end


  # defp username_contains(search_value) do
  #   user_list = Phos.Users.list_users()
  #   result = []
  #   case user_list do
  #     [_|_] ->
  #       result = Enum.filter(user_list, fn username -> String.contains?(username, search_value) end)

  #   end
  #   result
  # end
end
