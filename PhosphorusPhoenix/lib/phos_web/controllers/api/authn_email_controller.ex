defmodule PhosWeb.API.AuthNEmailController do
  use PhosWeb, :controller
  action_fallback PhosWeb.API.FallbackController
  alias Phos.Users

  plug :put_view, json: PhosWeb.API.AuthNEmailJSON

  def login(%Plug.Conn{assigns: %{current_user: anon}} = conn, %{"email" => email, "password" => password}) do
    with %Users.User{fyr_id: fyr_id} = user when not is_nil(fyr_id) <- Users.get_user_by_email_and_password(email, password),
         token <- Phos.External.GoogleIdentity.gen_customToken(fyr_id) do

      render(conn, :login, user: user, token: token)
    else
      %Users.User{email: ^email} = fyring_user ->
        # migrate fyr_id from anonymous user to user w email
        with %Users.User{email: nil, fyr_id: fyr_id} <- anon,
             :ok <- Users.migrate_fyr_user(anon, fyring_user),
               token <- Phos.External.GoogleIdentity.gen_customToken(fyr_id) do
          render(conn, :login, user: fyring_user, token: token)
        end

      _ -> {:error, :unprocessable_entity}
    end
  end


  #  ** (CaseClauseError) no case clause matching: {:ok, %HTTPoison.Response{status_code: 400, body: %{"error" => %{"code" => 400, "errors" => [%{"domain" => "global", "message" => "EMAIL_EXISTS", "reason" => "invalid"}], "message" => "EMAIL_EXISTS"}}, headers: [{"Pragma", "no-cache"}, {"Date", "Tue, 04 Apr 2023 09:59:03 GMT"}, {"Expires", "Mon, 01 Jan 1990 00:00:00 GMT"}, {"Cache-Control", "no-cache, no-store, max-age=0, must-revalidate"}, {"Vary", "X-Origin"}, {"Vary", "Referer"}, {"Content-Type", "application/json; charset=UTF-8"}, {"Server", "ESF"}, {"X-XSS-Protection", "0"}, {"X-Frame-Options", "SAMEORIGIN"}, {"X-Content-Type-Options", "nosniff"}, {"Alt-Svc", "h3=\":443\"; ma=2592000,h3-29=\":443\"; ma=2592000"}, {"Accept-Ranges", "none"}, {"Vary", "Origin,Accept-Encoding"}, {"Transfer-Encoding", "chunked"}], request_url: "https://www.googleapis.com/identitytoolkit/v3/relyingparty/setAccountInfo?key=AIzaSyDRHLjiQYE7ZhHXIh_CFN2rxNur2hBe_Dg", request: %HTTPoison.Request{method: :post, url: "https://www.googleapis.com/identitytoolkit/v3/relyingparty/setAccountInfo?key=AIzaSyDRHLjiQYE7ZhHXIh_CFN2rxNur2hBe_Dg", headers: [], body: "{\"email\":\"josephfoo96@gmail.com\",\"idToken\":\"eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg3YzFlN2Y4MDAzNGJiYzgxYjhmMmRiODM3OTIxZjRiZDI4N2YxZGYiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc2NyYXRjaGJhYy12MS1lZTExYSIsImF1ZCI6InNjcmF0Y2hiYWMtdjEtZWUxMWEiLCJhdXRoX3RpbWUiOjE2ODA2MDIzNDMsInVzZXJfaWQiOiJvZm1qMHR1Zlg5YXRjS1BHYThsVVlmNGNXYVUyIiwic3ViIjoib2ZtajB0dWZYOWF0Y0tQR2E4bFVZZjRjV2FVMiIsImlhdCI6MTY4MDYwMjM0MywiZXhwIjoxNjgwNjA1OTQzLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7fSwic2lnbl9pbl9wcm92aWRlciI6ImN1c3RvbSJ9fQ.HmiZieDR3iY7AaVxRxltBdbbxV4Qv-mkbP7SKrd490FY7WvObYQz0oCU7K-NLidHXpossV3I15oG2AWke84Okw5P01cRXjG8D0PvMdRQPXABLT4ope73aiAi0SA_XpF6wzjDh0T8KlzYSVwdiz1X-0dVwjkrp7yQDdc2YdcfppXYMReiFsJc0GSWdSPzhKZ51pZJ0ef0kthstUkdr1GXzFx1YOYIqSXZ39b7M6uVxuNQbrj0LVdqHR622m67EUKHO2g3HSpEfCS7gSrlcpqwyvvt_s3RLp82yTbxxjkDPl_z73UNcX52lGMXTB4XiCH7VR-Oa0pAoTloAuopv2b1cw\"}", params: %{}, options: []}}}
  #
  def register(%Plug.Conn{assigns: %{current_user: anon}} = conn, %{"email" => email, "password" => _password} = params) do
    with {:ok, user} <- Users.claim_anon_user(anon, params),
         Phos.External.GoogleIdentity.link_email(anon.fyr_id, email) do

      Users.deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))

      conn
      |> put_status(201)
      |> render("register.json", user: user)
    else
        _ -> {:error, :unprocessable_entity}

    end
  end


  def resend_confirmation(%Plug.Conn{assigns: %{current_user: %{email: email}}} = conn, _) do
    with %{confirmed_at: nil} = user <- Users.get_user_by_email(email) do

      Users.deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))

      conn
      |> put_status(201)
      |> render("resend_confirmation.json")
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
