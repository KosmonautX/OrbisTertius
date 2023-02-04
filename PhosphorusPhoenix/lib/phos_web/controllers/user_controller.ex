defmodule PhosWeb.UserController do
  use PhosWeb, :controller

  def show(conn, %{"id" => user} = _params) do
    render(conn, :show, user: user )
  end

  def show(conn, _params) do
    render(conn, :show, archetype: "Root")
  end

end
