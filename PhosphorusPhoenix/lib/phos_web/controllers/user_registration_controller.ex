defmodule PhosWeb.UserRegistrationController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.User
  alias PhosWeb.UserAuth

  def new(conn, _params) do
    changeset = Users.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset, telegram: Phos.OAuthStrategy.telegram())
  end

  def create(conn, %{"user" => user_params}) do
    case Users.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Users.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
