defmodule PhosWeb.Util.Authorization do
  def authorized?(%{assigns: %{session_token: token}} = _socket, id) when token != "" do
    case PhosWeb.Menshen.Auth.validate_user(token) do
      {:ok, %{"user_id" => user_id}} -> user_id == id
      _ -> false
    end
  end
  def authorized?(_, _), do: false
end
