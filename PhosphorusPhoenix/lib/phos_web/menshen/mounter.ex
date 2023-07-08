defmodule PhosWeb.Menshen.Mounter do
  import Phoenix.Component, only: [assign: 2]
  import Plug.Conn, only: [assign: 3]
  import Phoenix.LiveView, only: [get_connect_params: 1]

   @moduledoc """
  Supporting Mounting of distinct User Flows applied to all LiveViews attaching this hook.
  """

  @default_locale "en"
  @timezone "UTC"
  @timezone_offset 0

  def on_mount(:pleb, _params, %{"user_token" => token}, socket) do
    user =  Map.from_struct(Phos.Users.get_user_by_session_token(token))
    {:cont, assign(socket, guest: false, current_user: user)}
  end

  def on_mount(:pleb, _params, _session, socket) do
    {:cont, assign(socket, guest: true, current_user: nil)}
  end

  def on_mount(:admin, _params, _session, socket) do
    {:cont, assign(socket, page_title: "AdminWorld")}
  end

  def on_mount(:timezone, _params, _sessions, socket) do
    locale = get_connect_params(socket)["locale"] || @default_locale
    timezone = get_connect_params(socket)["timezone"] || @timezone
    timezone_offset = get_connect_params(socket)["timezone_offset"] || @timezone_offset

    {:cont,
       socket
       |> assign(:locale, locale)
       |> assign(:timezone, %{timezone: timezone, timezone_offset: timezone_offset})}
  end

  def init(opts), do: opts
  def call(conn, opts) do
    conn
    |> action(opts)
  end

  defp action(conn, :admin), do: assign(conn, :page_title, "AdminWorld")
  defp action(%{assigns: %{user_token: token}} = conn, _) when not is_nil(token) do
    user =  Map.from_struct(Phos.Users.get_user_by_session_token(token))
    assign(conn, :guest, false)
    |> assign(:current_user, user)
  end
  defp action(%{assigns: %{current_user: user}} = conn, _) do
    assign(conn, :guest, false)
    |> assign(:current_user, user)
  end
  defp action(conn, _), do: assign(conn, :guest, true) |> assign(:current_user, nil)

end
