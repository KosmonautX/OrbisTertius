defmodule PhosWeb.API.FyrAuthController do
  use PhosWeb, :controller
  alias PhosWeb.Menshen.Auth
  alias Phos.Users
  action_fallback PhosWeb.API.FallbackController

  def transmute(conn, %{"fyr" => fyr_token}) do
    with {:ok, %{"sub" => fyr_id}} <- Auth.validate_fyr(fyr_token) do
      case Users.get_user_by_fyr(fyr_id)  do
        user = %Users.User{} ->
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


  def genesis(conn, %{"fyr" => fyr_token}) do
    with {:ok, %{"sub" => fyr_id}} <- Auth.validate_fyr(fyr_token),
         {:ok, user_data} <- PhosWeb.Util.Migrator.fyr_profile(fyr_token) do
      json(conn, %{user_id: user_data.user.id, email: user_data.user.email, payload: Auth.generate_user!(user_data.user.id)})

    else
      {:error, _reason} -> {:error, :unprocessable_entity}
    end
  end

  def genesis(_conn, _) do
    {:error, :unprocessable_entity}
  end

end
