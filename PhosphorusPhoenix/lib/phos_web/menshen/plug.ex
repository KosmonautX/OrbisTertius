defmodule PhosWeb.Menshen.Plug do
  import Plug.Conn
  alias PhosWeb.Menshen.Auth

  def init(opts), do: opts

  @spec authorize_user(Plug.Conn.t(), any) :: Plug.Conn.t()
  def authorize_user(conn, _opts) do
    with [jwt | _tail] when is_binary(jwt) <- get_req_header(conn, "authorization"),
         {:ok , claims} <- Auth.validate_user(jwt) do
      conn |> shallPass(claims)
      else
        _ -> conn |> shallNotPass
    end


  end

  defp shallPass(conn, %Phos.Users.User{} = user), do: assign(conn, :current_user, user)
  defp shallPass(conn, %{"user_id" => user_id} = _claims) do
    case Phos.Users.find_user_by_id(user_id) do
      {:ok, user} -> shallPass(conn, user)
      _ -> shallNotPass(conn)
    end
  end

  defp shallNotPass(conn) do
    conn
    |> put_status(:unauthorized)
    |> resp(401, "Begone Heathen")
    |> halt()
  end
end
