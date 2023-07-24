defmodule PhosWeb.Components.ListMessage do
  use PhosWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={"#{@id}-infinite-scroll-body"} class="lg:mt-0">
      <.list_message id={@id} memories={@memories} current_user={@current_user} timezone={@timezone} />
    </div>
    """
  end
end
