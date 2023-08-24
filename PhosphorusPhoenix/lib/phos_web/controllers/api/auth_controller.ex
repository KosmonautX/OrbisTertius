defmodule PhosWeb.API.FyrAuthController do
  use PhosWeb, :controller
  alias PhosWeb.Menshen.Auth
  alias Phos.Users
  action_fallback PhosWeb.API.FallbackController

  def transmute(conn, %{"fyr" => fyr_token}) do
    with {:ok, %{"sub" => fyr_id, "email" => email}} <- Auth.validate_fyr(fyr_token) do
      case Users.get_user_by_email(email) do
        user = %Users.User{} ->
          json(conn, %{payload: Auth.generate_user!(user.id)})

        nil -> case Users.get_user_by_fyr(fyr_id) do
                 user = %Users.User{} ->
                   json(conn, %{payload: Auth.generate_user!(user.id)})

                 nil  -> {:error, :not_found}
               end
        _ -> {:error, :not_found}
      end
    else
      {:ok, %{"sub" => fyr_id}} ->
        case Users.get_user_by_fyr(fyr_id) do
          user = %Users.User{} ->
            json(conn, %{payload: Auth.generate_user!(user.id)})

          nil  -> {:error, :not_found}
        end

      {:error, _reason} -> {:error, :unprocessable_entity}
    end
  end


  def genesis(conn, %{"fyr" => fyr_token}) do
    with {:ok, %{"sub" => _fyr_id}} <- Auth.validate_fyr(fyr_token),
         {:ok, user_data} <- PhosWeb.Util.Migrator.fyr_profile(fyr_token) do
      conn
      |> put_status(:created)
      |> json(%{user_id: user_data.user.id,
               email: user_data.user.email,
               payload: Auth.generate_user!(user_data.user.id)})

    else
      {:error, _reason} -> {:error, :unprocessable_entity}
    end
  end

  def genesis(_conn, _) do
    {:error, :unprocessable_entity}
  end

  def semver(conn, %{"version" => version}) do
    latest = "2.1.1" # latest patch
    earliest = "2.0.0" # below current minor version
    response = cond do
      Version.match?(version, ">= " <> latest) ->
        "ignore"

      Version.match?(version, "~> " <> earliest) ->
        "recommend"

      true ->
        "force"
    end

    conn
      |> put_status(200)
      |> json(%{update: response})
   end

end
