defmodule PhosWeb.Timezone do
  use PhosWeb, :live_component

  @default_locale "en"
  @timezone "UTC"
  @timezone_offset 0

  def on_mount(:timezone, _params, _session, socket) do
    locale = get_connect_params(socket)["locale"] || @default_locale
    timezone = get_connect_params(socket)["timezone"] || @timezone
    timezone_offset = get_connect_params(socket)["timezone_offset"] || @timezone_offset

    {:cont,
     socket
     |> assign(:locale, locale)
     |> assign(:timezone, %{timezone: timezone, timezone_offset: timezone_offset})}
  end
end
