defmodule PhosWeb.PageController do
  use PhosWeb, :controller

  def index(%{assigns: assigns} = conn, _params) do
    render(conn, :index)
  end

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def agent(conn, _params) do
    render(conn, :agent)
  end

  def welcome(conn, _params) do
    render(conn, :welcome)
  end
end
