defmodule PhosWeb.PageControllerTest do
  use PhosWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Scratchbac!"
  end
end