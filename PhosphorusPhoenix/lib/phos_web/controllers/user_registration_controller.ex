defmodule PhosWeb.UserRegistrationController do
  use PhosWeb, :controller

  alias Phos.Users
  alias Phos.Users.User

  def new(conn, _params) do
    changeset = Users.change_user_registration(%User{})
    render(conn, :new, changeset: changeset, telegram: Phos.OAuthStrategy.telegram())
  end

  def create(conn, %{"user" => user_params}) do
    user_params = Map.put(user_params, "public_profile", %{bio: "I'm new to Scratchbac!", birthday: nil, occupation: "Scratchbacker", honorific: nil, traits: []})
    case Users.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Users.deliver_user_confirmation_instructions(
            user,
            fn token -> ~p"/users/confirm/#{token}" end)

        conn
        |> put_flash(:info, "User created successfully.")
        |> PhosWeb.Menshen.Gate.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, telegram: Phos.OAuthStrategy.telegram())
    end
  end
end
