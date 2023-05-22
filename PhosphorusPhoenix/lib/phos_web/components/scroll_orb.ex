defmodule PhosWeb.Components.ScrollOrb do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div>
      <div id={@id <> "infinite-scroll-body"} phx-update="stream" phx-viewport-bottom={"load-more"} phx-value-archetype={"orb-ally"} class="flex flex-col gap-2 ">
        <div :for={{_dom_id, orb} <- @streams.orbs} id={"orb-divided-#{random_id()}"}>
          <.scry_orb id={"orb-history-#{random_id()}"} orb={orb} timezone={@timezone1} />
        </div>
      </div>
    </div>
    """
  end
end
