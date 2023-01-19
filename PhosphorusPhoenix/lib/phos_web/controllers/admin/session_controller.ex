defmodule PhosWeb.AdminSessionController do
  use PhosWeb, :controller
  use PhosWeb, :verified_routes

  plug :put_root_layout, {PhosWeb.Layouts, :admin_root}
  #plug :put_layout, {PhosWeb.LayoutView, :admin}

  def index(conn, _params) do
    conn
    |> redirect(to: ~p"/admin/sessions/new")
    |> halt()
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user_params}) do
    with password <- Map.get(user_params, "password", ""),
         true <- password != "",
         {:ok, token} <- Phos.Admin.authenticate(password) do
      conn
      |> configure_session(renew: true)
      |> clear_session()
      |> put_session(:admin_token, token)
      |> put_session(:live_socket_id, "admin_sessions:#{Base.url_encode64(token)}")
      |> put_flash(:info, String.capitalize("sike you are still in the matrix  🔵💊🔴"))
      |> redirect(to: ~p"/admin/orbs")
      |> halt()
    else
      {_, msg} -> render_unauthenticate(conn, msg)
      _ -> render_unauthenticate(conn)
    end
  end

  defp render_unauthenticate(conn, msg \\ "Invalid password") do
    conn
    |> put_flash(:error, String.capitalize(msg))
    |> redirect(to: ~p"/admin/sessions/new")
    |> halt()
  end
end
