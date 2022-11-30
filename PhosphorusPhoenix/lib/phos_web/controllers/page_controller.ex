defmodule PhosWeb.PageController do
  use PhosWeb, :controller

  def index(%{assigns: assigns} = conn, _params) do
    IO.inspect(assigns)
    render(conn, :index)
  end

  def agent(conn, _params) do
    render(conn, :agent)
  end
end
