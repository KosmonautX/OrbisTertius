defmodule PhosWeb.API.DevlandView do
  use PhosWeb, :view

  def render(conn, "token.json", %{token: token}) do
    %{token: token}
  end

end
