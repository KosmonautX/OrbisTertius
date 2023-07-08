defmodule PhosWeb.Components.ScrollAlly do
  use PhosWeb, :live_component
# if(@ally_page > 1, do: "pt-[calc(200vh)]"),
  def render(assigns) do
    ~H"""
    <div>
      <div
        id={@id <> "infinite-scroll-body"}
        phx-update="stream"
        phx-viewport-bottom={@meta.pagination.downstream && "load-more"}
        phx-value-archetype="ally"
        class={[
          if(@meta.pagination.downstream, do: "pb-[calc(200vh)]"),

          "w-full px-4 lg:px-0"
        ]}
      >
        <.user_info_bar
          :for={{dom_id, ally} <- @data}
          :if={!is_nil(Map.get(ally, :username))}
          id={"user-#{dom_id}-infobar"}
          user={ally}
          show_padding={false}
          class="border-b border-gray-300 lg:border-0"
        >
          <:information>
            <%= ally
            |> get_in([Access.key(:public_profile, %{}), Access.key(:occupation, "Community Member")]) %>
          </:information>
          <:actions>
            <.live_component
              id={"ally_component_infinite_scroll_#{ally.id}"}
              module={PhosWeb.Component.AllyButton}
              current_user={@current_user}
              socket={@socket}
              parent_pid={@parent_pid}
              user={ally}
            />
          </:actions>
        </.user_info_bar>
      </div>
    </div>
    """
  end



  #ally_list is a wrapper fn around Folk.friends() according to current_user, user found in socket


  defp ally_list(current_user, friend, page, limit \\ 24)
  defp ally_list(%Phos.Users.User{id: id} = _current_user, friend, page, limit),
    do: ally_list(id, friend, page, limit)

  defp ally_list(current_user, %Phos.Users.User{id: id} = _friend, page, limit),
    do: ally_list(current_user, id, page, limit)

  defp ally_list(current_user_id, friend_id, page, limit)
       when is_bitstring(current_user_id) and is_bitstring(friend_id) do
    case friend_id == current_user_id do
      false ->
        Phos.Folk.friends({friend_id, current_user_id}, page, :completed_at, limit)
        # |> Map.get(:data, [])

      _ ->
        Phos.Folk.friends(current_user_id, page, :completed_at, limit)
        # |> Map.get(:data, [])
        #|> Enum.map(&Map.get(&1, :friend))
    end
  end

  defp ally_list(nil, friend_id, page, limit),
    do:
      Phos.Folk.friends(friend_id, page, :completed_at, limit)
      # |> Map.get(:data, []) #|> Enum.map(&Map.get(&1, :friend))

  defp ally_list(_, _, _, _), do: []

  def check_more_ally(currid, userid, expected_ally_page, _limit) do
    ally_list(currid, userid, expected_ally_page)
  end
end
