defmodule PhosWeb.Components.ScrollOrb do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div >
      <div id="infinite-scroll-body" phx-update="append" class="flex flex-col gap-2">
        <%= for orb <- @orbs do %>
        <div id={"orb-divided-#{random_id()}"} class="border border-gray-200 rounded-xl shadow-md dark:border-gray-700">
          <.scry_orb id={"orb-history-#{random_id()}"} orb={orb} timezone={@timezone1}/>
        </div>
        <% end %>
      </div>
      <div id="infinite-scroll-marker" phx-hook="Scroll" data-page={@page}></div>
    </div>
    """
  end
end
