defmodule PhosWeb.Menshen.Plug do
  import Plug.Conn
  alias PhosWeb.Menshen.Auth

  def init(opts), do: opts

  @spec fetch_authorised_user_claims(Plug.Conn.t(), any) :: Plug.Conn.t()
  def fetch_authorised_user_claims(conn, _opts) do
    jwt = get_req_header(conn, "authorization")
    case Auth.validate_user(List.first(jwt)) do
      {:ok , claims} ->
        conn |> shallPass(claims)
      { :error, _error } ->
        conn |> shallNotPass
    end
  end

  defp shallPass(conn, %Phos.Users.User{} = user), do: assign(conn, :current_user, user)
  defp shallPass(conn, %{"user_id" => user_id} = _claims) do
    case should_get_user(user_id) do
      {:ok, user} -> shallPass(conn, user)
      _ -> shallNotPass(conn)
    end
  end

  defp should_get_user(user_id) do
    case Phos.Cache.get({Phos.Users.User, :logged_in, user_id}) do
      nil -> do_get_user(user_id)
      user -> {:ok, user}
    end
  end

  defp do_get_user(user_id) do
    case Phos.Users.find_user_by_id(user_id) do
      {:ok, user} = data -> Phos.Cache.put({Phos.Users.User, :logged_in, user_id}, user, ttl: :timer.minutes(10))
        data
      err -> err
    end
  end

  defp shallNotPass(conn) do
    conn
    |> put_status(:unauthorized)
    |> resp(401, "Begone Heathen")
    |> halt()
  end
end
