defmodule PhosWeb.UserSettingsController do
  use PhosWeb, :controller

  alias Phos.Users
  alias PhosWeb.UserAuth

  plug :assign_email_and_profile_and_password_changesets

  def edit(%{assigns: %{current_user: user}} = conn, _params) do
    user = Phos.Repo.preload(user, :auths)
    render(conn, :edit, current_user: user)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Users.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Users.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          fn token -> ~p"/users/settings/confirm_email/#{token}" end)

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        render(conn, :edit, email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Users.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, ~p"/users/settings")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_public_profile"} = params) do
    %{"user" => %{"username" => username}} = params
    user = conn.assigns.current_user


    # Setting Page to Integrate Oauth with alternate Logins
    # Telegram Integration
    # Setting Public Profile IMage etc

    case Users.update_pub_user(user, %{username: username}) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Username updated successfully.")
        |> redirect(to: ~p"/users/settings")
        # |> put_session(:user_return_to, Routes.orb_index_path(conn, :index))
        # |> UserAuth.log_in_user(user) # remember to implement token for oatuh temporary sol above

      {:error, changeset} ->
        render(conn, :edit, pub_profile_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Users.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/users/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp assign_email_and_profile_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Users.change_user_email(user))
    |> assign(:password_changeset, Users.change_user_password(user))
    |> assign(:pub_profile_changeset, Users.change_pub_profile(user))
    |> assign(:telegram_changeset, Users.change_telegram_login(user))
  end
end
