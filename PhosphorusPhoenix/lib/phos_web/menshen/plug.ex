defmodule PhosWeb.Menshen.Plug do
  import Plug.Conn
  alias PhosWeb.Menshen.Auth

  def init(opts), do: opts

  @spec authorize_user(Plug.Conn.t(), any) :: Plug.Conn.t()
  def authorize_user(conn, _opts) do
    jwt = get_req_header(conn, "authorization")
    case Auth.validate_user(List.first(jwt)) do
      {:ok , claims} ->
        conn |> shallPass(claims)
      { :error, _error } ->
        conn |> shallNotPass
    end
  end

  defp shallPass(conn, claims) do
    conn
    |> assign(:current_user, claims)
  end

  defp shallNotPass(conn) do
    conn
    |> put_status(:unauthorized)
    |> resp(401, "Begone Heathen")
    |> halt()
  end

end
