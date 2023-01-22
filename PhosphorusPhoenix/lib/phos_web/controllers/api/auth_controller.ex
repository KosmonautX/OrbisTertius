defmodule PhosWeb.API.FyrAuthController do
  use PhosWeb, :controller
  alias PhosWeb.Menshen.Auth
  alias Phos.Users
  action_fallback PhosWeb.API.FallbackController

  plug :put_view, json: PhosWeb.Api.AuthJSON

  def transmute(conn, %{"fyr" => fyr_token}) do
    with {:ok, %{"sub" => fyr_id}} <- Auth.validate_fyr(fyr_token) do
      case Users.get_user_by_fyr(fyr_id)  do
        user = %Users.User{} ->
          json(conn, %{payload: Auth.generate_user!(user.id)})
        nil ->
          {:error, :not_found}
          # Migration Season Ended
          # case PhosWeb.Util.Migrator.user_profile(fyr_id) do
          #   {:ok, users} ->
          #     conn
          #     |> put_status(:created)
          #     |> json(%{payload: Auth.generate_user!(List.first(users).id)})
          #   {:error, _reason} -> {:error, :not_found}
          # end
        _ -> {:error, :not_found}
      end
    else
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
    latest = "1.2.10" # latest patch
    earliest = "1.2.10" # below current minor version
    response = cond do
      Version.match?(version, "~> #{latest}") ->
        "ignore"

      Version.match?(version, "~> #{earliest}") ->
        "recommend"

      true ->
        "force"
    end

    conn
      |> put_status(200)
      |> json(%{update: response})
   end

end
