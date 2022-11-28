defmodule PhosWeb.PageController do
  use PhosWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def agent(conn, _params) do
    render(conn, :agent)
  end
end
