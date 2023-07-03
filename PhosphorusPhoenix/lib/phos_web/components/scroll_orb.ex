defmodule PhosWeb.Components.ScrollOrb do
  use PhosWeb, :live_component
  alias Phos.Action
  # if(@orb_page > 1, do: "pt-[calc(200vh)]"),
  def render(assigns) do
    ~H"""
    <div>
      <div
        id={@id <> "infinite-scroll-body"}
        phx-update="stream"
        phx-viewport-bottom={@meta.pagination.downstream && "load-more"}
        phx-value-archetype="orb"
        class={[
          if(@meta.pagination.downstream, do: "pb-[calc(200vh)]"),
          "flex flex-col gap-2"
        ]}
      >
        <div :for={{dom_id, orb} <- @data} id={"orb-divided-#{dom_id}"} class="absloute">
          <.scry_orb
            id={"#{@id}-orb-history-#{dom_id}"}
            orb={orb}
            timezone={@timezone1}
            profile_img={@profile_img}
            show_user={@show_user}
            show_info={@show_info}
            show_information={false}
            show_padding={@show_padding}
            orb_color={false}
            show_location={true}
            color={@color}
          />
        </div>
      </div>
    </div>
    """
  end

  def check_more_orb(userid, expected_orb_page) do
    Action.orbs_by_initiators([userid], expected_orb_page)
  end
end
