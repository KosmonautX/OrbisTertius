defmodule PhosWeb.Api.AuthJSON do
  def index(%{user: user}), do: %{data: privileged_user(user)}
  def update(%{user: user}), do: %{data: privileged_user(user)}
  def login(%{user: user, token: token}) do
    %{
      data: privileged_user(user),
      token: token
    }
  end
  def register(%{user: user}), do: %{data: privileged_user(user)}
  def user(%{user: user}), do: %{username: user.username}

  def forgot_password(_), do: %{messages: ["If the account exists, we've sent an email."]}
  def reset_password(_), do: %{messages: ["Successfully reset password."]}
  def confirm_email(_), do: %{messages: ["Successfully confirmed email."]}

  defp privileged_user(user), do: Map.take(user, [:id, :username, :email, :full_name])
end
