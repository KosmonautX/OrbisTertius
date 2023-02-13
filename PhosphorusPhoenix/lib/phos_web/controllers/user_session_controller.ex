defmodule PhosWeb.UserSessionController do
  use PhosWeb, :controller

  alias Phos.Users
  alias PhosWeb.Menshen.Gate

  def new(conn, _params) do
    render(conn, :new, error_message: nil, telegram: Phos.OAuthStrategy.telegram())
  end

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Welcome to Scratchbac!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password} = emailnpassword} = _params, info \\ "Welcome back!") do
    if user = Users.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> Gate.log_in_user(user, emailnpassword)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> Gate.log_out_user()
  end
end
