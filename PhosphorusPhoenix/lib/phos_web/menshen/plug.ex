defmodule PhosWeb.Menshen.Plug do
  import Plug.Conn
  alias PhosWeb.Menshen.Auth

  def init(opts), do: opts

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    jwt = fetchToken(conn)
    case Auth.validate_user(jwt) do
      {:ok , claims} ->
        conn |> shallPass(claims)
      { :error, _error } ->
        conn |> shallNotPass
    end
  end

  defp shallPass(conn, claims) do
    conn
    |> assign(:claim, claims )
  end

  defp shallNotPass(conn) do
    conn
    |> put_status(:unauthorized)
    |> halt
  end

  defp fetchToken(%{"session_token" => jwt}= _conn), do: jwt



end
