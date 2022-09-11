defmodule PhosWeb.API.AuthController do
  use PhosWeb, :controller
  alias PhosWeb.Menshen.Auth
  alias Phos.Users
  action_fallback PhosWeb.API.FallbackController

  def authenticate_user(conn, %{"fyr" => fyr_token}) do
    with {:ok, %{"sub" => fyr_id}} <- Auth.validate_fyr(fyr_token),
      user = Users.get_user_by_fyr(fyr_id) do

      case user do
        %Users.User{} ->
          json(conn, %{payload: Auth.generate_user!(user.id)})
        nil ->
          case PhosWeb.Util.Migrator.user_profile(fyr_id) do
            {:ok, users} ->
              json(conn, %{payload: Auth.generate_user!(List.first(users).id)})
            {:error, _reason} -> {:error, :not_found}
          end
       end
    else
      {:error, _reason} -> {:error, :unprocessable_entity}
     end
    end
end
