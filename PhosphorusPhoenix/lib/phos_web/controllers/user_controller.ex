defmodule PhosWeb.UserController do
  use PhosWeb, :controller

  def show(conn, %{"id" => user} = _params) do
    render(conn, "show.html", user: user )
  end

  def show(conn, _params) do
    render(conn, "show.html", archetype: "Root" )
  end

end
