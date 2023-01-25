defmodule PhosWeb.Components.ScrollAlly do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div>
      <div id="infinite-scroll-body" phx-update="append">
        <%= for ally <- @ally_list do %>
          <.user_info_bar id={"user-#{random_id()}-infobar"} user={ally}>
            <:information>
              Members, 25
            </:information>
            <:actions>
              <.button class="flex items-center p-0">
                <Heroicons.plus class="mr-2 -ml-1 lg:w-6 lg:h-6 w-4 h-4 " />
                <span>Ally</span>
              </.button>
            </:actions>
          </.user_info_bar>
        <% end %>
      </div>
      <div id="infinite-scroll-marker" phx-hook="Scroll" data-page={@page}></div>
    </div>
    """
  end
end
