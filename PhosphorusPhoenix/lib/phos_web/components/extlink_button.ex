defmodule PhosWeb.Components.ExtLinkButton do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div>
      <%= @label %>
    </div>
    """
  end
end
