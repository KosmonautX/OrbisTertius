defmodule PhosWeb.ArchetypeController do
  use PhosWeb, :controller

  def show(conn, %{"id" => agent} = _params) do
    render(conn, :show, agent: agent )
  end

  def show(conn, _params) do
    render(conn, :show, archetype: "Root" )
  end


end
