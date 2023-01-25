defmodule PhosWeb.Components.ScrollOrb do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div>
      <div id="infinite-scroll-body" phx-update="append">
        <%= for orb <- @orbs do %>
          <.user_info_bar id="orb-initiator-profile-upload" user={orb.initiator}>
            <:information>
              <span>
                <Heroicons.map_pin class="mt-0.5 h-4 w-4" />
              </span>
              Chennai
            </:information>
            <:actions>
              <.button tone={:icons}>
                <Heroicons.ellipsis_vertical class="mt-0.5 lg:h=10 lg:w-10 h-6 w-6 text-black" />
              </.button>
            </:actions>
          </.user_info_bar>

          <.post_image :if={orb.media} orb={orb} id="orb-post-image" />
          <.post_information title={orb.title} />
          <.comment_action />
        <% end %>
      </div>
      <div id="infinite-scroll-marker" phx-hook="Scroll" data-page={@page}></div>
    </div>
    """
  end
end
