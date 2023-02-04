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

  defp get_current_end_date(socket, timezone) do
    current_date =
      timezone
      # in UTC time
      |> Timex.today()
      |> Timex.to_naive_datetime()
      |> Timex.shift(hours: -1 * socket.assigns.timezone_offset)

    end_date =
      current_date
      |> Timex.shift(days: 1)

    assign(socket, current_date: current_date, end_date: end_date)
  end
end
