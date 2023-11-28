defmodule PhosWeb.ErrorController do
  use PhosWeb, :controller

  def _404(conn, _params) do
    conn
    |> assign(:reason, %{message: "Under Construction"})
    |> render(:"404", layout: false)
  end
end
