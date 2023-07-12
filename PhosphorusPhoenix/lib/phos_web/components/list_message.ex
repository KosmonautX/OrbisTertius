defmodule PhosWeb.Components.ListMessage do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div id={"#{@id}-infinite-scroll-body"} class="lg:mt-0">
      <.list_message
        id={@id}
        memories={@memories}
        current_user={@current_user}
        timezone={@timezone}
        metadata={@metadata}
      />
    </div>
    """
  end
end
