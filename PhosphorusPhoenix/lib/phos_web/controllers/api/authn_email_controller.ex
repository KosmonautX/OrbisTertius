defmodule PhosWeb.API.AuthNEmailController do
  use PhosWeb, :controller
  action_fallback PhosWeb.API.FallbackController
  alias Phos.Users

  plug :put_view, json: PhosWeb.API.AuthNEmailJSON

  def login(%Plug.Conn{assigns: %{current_user: _anon}} = conn, %{"email" => email, "password" => password}) do
    with %Users.User{fyr_id: fyr_id} = user <- Users.get_user_by_email_and_password(email, password),
         token <- Phos.External.GoogleIdentity.gen_customToken(fyr_id) do

      render(conn, :login, user: user, token: token)
    else
      %Users.User{email: ^email} = _user ->
        # no fyr_id yet path
        IO.inspect("Untie his fyr_id from current_user")

      _ -> {:error, :unprocessable_entity}
    end
  end

  def register(%Plug.Conn{assigns: %{current_user: anon}} = conn, %{"email" => email, "password" => _password} =params) do
    with {:ok, user} <- Users.claim_anon_user(anon, params),
      Phos.External.GoogleIdentity.link_email(anon.fyr_id, email) do

      Users.deliver_user_confirmation_instructions(user, fn token -> "#{token}" end)

      conn
      |> put_status(201)
      |> render("register.json", user: user)
    end
  end

  def forgot_password(conn, %{"email" => email}) do
    if user = Users.get_user_by_email(email) do
      # Build your token url here...
      Users.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
      #Users.deliver_user_reset_password_instructions(user, fn token -> "#{token}" end)
    end

    # Render the same view to prevent enumeration attacks.
    render(conn, "forgot_password.json")
  end

  def reset_password(conn, %{
        "token" => token,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do

    with user = %Users.User{id: _} <- Users.get_user_by_reset_password_token(token),
         {:ok, _} <- Users.reset_user_password(user, %{password: password, password_confirmation: password_confirmation}) do
      render(conn, "reset_password.json")
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :unprocessable_entity}
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Users.confirm_user(token) do
      {:ok, _} ->
        render(conn, "confirm_email.json")

      :error ->
        {:error, :bad_request, "Invalid confirmation token."}
    end
  end
end
