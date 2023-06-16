defmodule PhosWeb.Components.ListMessage do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div>
      <div id={"#{@id}-infinite-scroll-body"} phx-update="prepend" phx-hook="ScrollTop">
        <.list_message
          id={"list-more-message-#{random_id()}"}
          memories={@memories}
          current_user={@current_user}
          timezone={@timezone}
        />
      </div>
    </div>
    """
  end
end
