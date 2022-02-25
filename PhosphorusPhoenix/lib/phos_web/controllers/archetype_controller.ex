defmodule PhosWeb.ArchetypeController do
  use PhosWeb, :controller

  def show(conn, %{"id" => agent} = _params) do
    render(conn, "show.html", agent: agent )
  end

  def show(conn, _params) do
    render(conn, "show.html", archetype: "Root" )
  end


end
