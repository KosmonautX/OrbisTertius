defmodule PhosWeb.Menshen.Plug do
  import Plug.Conn
  alias PhosWeb.Menshen.Auth

  def init(opts), do: opts

  @spec authorized_user(Plug.Conn.t(), any) :: Plug.Conn.t()
  def authorized_user(conn, _opts) do
    with [jwt | _tail] when is_binary(jwt) <- get_req_header(conn, "authorization"),
         {:ok , claims} <- Auth.validate_user(jwt) do
      conn |> shall_pass(claims)
      else
        _ -> conn |> shall_no_pass()
    end
  end

  defp shall_pass(conn, %Phos.Users.User{} = user), do: assign(conn, :current_user, user)
  defp shall_pass(conn, %{"user_id" => user_id} = _claims) do
    case Phos.Users.find_user_by_id(user_id) do
      {:ok, user} -> shall_pass(conn, user)
      _ -> shall_no_pass(conn)
    end
  end

  defp shall_no_pass(conn) do
    conn
    |> put_status(:unauthorized)
    |> resp(401, "Begone Heathen")
    |> halt()
  end
end
