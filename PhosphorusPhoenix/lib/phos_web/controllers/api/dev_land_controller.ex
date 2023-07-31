defmodule PhosWeb.API.DevLandController do
  use PhosWeb, :controller
  alias PhosWeb.Menshen.Auth
  action_fallback PhosWeb.API.FallbackController


  def new(conn, %{"user" => "random"}) do
    user_id = List.first(Phos.Users.list_users()).id
    {:ok, token, _claims} = gen_token(user_id)
    json(conn, %{payload: token})
  end

  def new(conn, %{"user" => user_id}) do
    {:ok, token, _claims} = gen_token(user_id)
    json(conn, %{payload: token})
  end

  def fyr(conn, %{"fyr_id" => fyr_id}) do
    token = Phos.External.GoogleIdentity.gen_id_token(fyr_id)
    json(conn, %{payload: token})
  end

  defp gen_token(user_id), do: Auth.generate_user(user_id)
end
