defmodule PhosWeb.Components.ScrollAlly do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div>
      <div id="infinite-scroll-body" phx-update="append" class="overflow-x">
        <.user_info_bar
          :for={ally <- @ally_list}
          :if={!is_nil(Map.get(ally, :username))}
          id={"user-#{random_id()}-infobar"}
          user={ally}
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
              user={ally}
            />
          </:actions>
        </.user_info_bar>
      </div>
      <div id="infinite-scroll-marker" phx-hook="Scroll" data-page={@page} />
    </div>
    """
  end
end
