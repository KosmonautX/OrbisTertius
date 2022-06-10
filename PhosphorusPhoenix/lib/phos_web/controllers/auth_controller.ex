defmodule PhosWeb.AuthController do
  use PhosWeb, :controller
  plug Ueberauth

  alias Ueberauth.Strategy.Helpers

  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Phos.Users.from_auth(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticate")
        |> put_session(:current_user, user)
        |> configure_session(renew: true)
        |> redirect(to: "/")
      {_, _, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/sign_up")
    end
  end
end
