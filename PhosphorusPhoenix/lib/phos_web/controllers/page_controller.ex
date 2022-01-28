defmodule PhosWeb.PageController do
  use PhosWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def agent(conn, _params) do
    render(conn, "agent.html")
  end
end
