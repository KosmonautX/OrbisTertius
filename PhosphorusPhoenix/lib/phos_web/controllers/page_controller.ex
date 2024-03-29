defmodule PhosWeb.PageController do
  use PhosWeb, :controller

  def index(%{assigns: _assigns} = conn, _params) do
    render(conn, :index)
  end

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def redirect(conn, %{"out" => out}) do
    conn
    |> assign(:out, out)
    |> render(:redirect, layout: false)
  end

  def redirect(conn, _params) do
    render(conn, :redirect, layout: false)
  end

  def welcome(conn, _params) do
    render(conn, :welcome)
  end
end
