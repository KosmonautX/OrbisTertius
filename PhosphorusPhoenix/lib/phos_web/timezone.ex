defmodule PhosWeb.Timezone do
  use PhosWeb, :live_component

  @default_locale "en"
  @timezone "UTC"
  @timezone_offset 0

  def on_mount(:timezone, _params, session, socket) do
    locale = get_connect_params(socket)["_locale"] || @default_locale
    timezone = get_connect_params(socket)["_timezone"] || @timezone
    timezone_offset = get_connect_params(socket)["_timezone_offset"] || @timezone_offset

    {:cont,
     socket
     |> assign(:locale, locale)
     |> assign(:timezone, %{timezone: timezone, timezone_offset: timezone_offset})}
  end

  def render(assigns) do
    ~H"""
    <!-- Your LiveView template code here -->
    """
  end
end
