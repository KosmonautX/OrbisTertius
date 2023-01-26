defmodule PhosWeb.Components.ScrollOrb do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div>
      <div id="infinite-scroll-body" phx-update="append">
        <%= for orb <- @orbs do %>
          <.scry_orb id={"orb-history-#{random_id()}"} orb={orb}>
          </.scry_orb>
        <% end %>
      </div>
      <div id="infinite-scroll-marker" phx-hook="Scroll" data-page={@page}></div>
    </div>
    """
  end
end
