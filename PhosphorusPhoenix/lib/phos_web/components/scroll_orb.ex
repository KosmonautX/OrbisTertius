defmodule PhosWeb.Components.ScrollOrb do
  use PhosWeb, :live_component
  alias Phos.Action

  def render(assigns) do
    ~H"""
    <div>
      <div id={@id <> "infinite-scroll-body"} phx-update="stream" phx-viewport-bottom={!@end_of_orb? && "load-more"} phx-value-archetype={"orb"} class="flex flex-col gap-2 ">
        <div :for={{dom_id, orb} <- @streams.orbs} id={"orb-divided-#{dom_id}"}>
          <.scry_orb id={"orb-history-#{dom_id}"} orb={orb} timezone={@timezone1} />
        </div>
      </div>
    </div>
    """
  end

  def check_more_orb(userid, expected_orb_page) do
    case Action.orbs_by_initiators([userid], expected_orb_page).data do
      [] -> {:ok, []}
      [_|_] = orbs -> {:ok, orbs}
    end
  end

end
