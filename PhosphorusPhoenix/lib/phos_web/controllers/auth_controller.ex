defmodule PhosWeb.AuthController do
  use PhosWeb, :controller
  alias Phos.Users

  def request(conn, %{"provider" => provider}) do
    redirect(conn, external: Phos.OAuthStrategy.request(provider))
    |> halt()
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> clear_session()
    |> redirect(to: "/")
  end

  def callback(conn, %{"provider" => provider, "format" => "json"} = params) do
    options = Enum.reject(params, fn {k, _} -> k == "provider" end) |> Enum.into(%{})
    case Phos.OAuthStrategy.callback(provider, options) do
      {:ok, %{user: data}} ->
        data
        |> Map.put("provider", provider)
        |> Phos.Users.from_auth()
        |> case do
          {:ok, user} -> render(conn, "callback.json", user: Phos.Repo.preload(user, [:private_profile]))
          {_, reason} ->
            conn
            |> put_status(:bad_request)
            |> render("error.json", reason: reason)
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render("unauthorized.json")
    end
  end

  def callback(conn, %{"provider" => provider} = params) do
    options = Enum.reject(params, fn {k, _} -> k == "provider" end) |> Enum.into(%{})
    case Phos.OAuthStrategy.callback(provider, options) do
      {:ok, %{user: user}} ->
        Map.put(user, "provider", provider)
        |> do_authenticate(conn)
      _ ->
        conn
        |> put_flash(:error, "Failed authenticate via #{String.capitalize(provider)}.")
        |> redirect(to: "/")
    end
  end

  def apple_callback(conn, params) do
    options = Map.put(params, "provider", "apple")
    case Phos.OAuthStrategy.callback("apple", options) do
      {:ok, %{user: user}} ->
        Map.put(user, "provider", "apple")
        |> do_authenticate(conn)
      err ->
        conn
        |> put_flash(:error, "Failed authenticate via Apple.")
        |> redirect(to: "/")
    end
  end

  defp do_authenticate(%{"provider" => _provider} = auth, conn) do
    case Phos.Users.from_auth(auth) do
    {:ok, user} ->
        token = Users.generate_user_session_token(user)
        conn
        |> put_flash(:info, "Authenticated via #{String.capitalize(to_string(auth["provider"]))}")
        |> renew_session
        |> put_session(:user_token, token)
        |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
        |> username_decider(user)
      {_, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/sign_up")
    end
  end


  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp username_decider(conn, %{username: username}) when username == "" or is_nil(username) do
    redirect(conn, to: Routes.user_settings_path(conn, :edit))
  end
  defp username_decider(conn, _), do: redirect(conn, to: "/orb")
end
