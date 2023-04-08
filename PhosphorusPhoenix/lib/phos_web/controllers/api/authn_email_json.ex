defmodule PhosWeb.API.AuthNEmailJSON do
  def login(%{user: user, token: token}) do
    %{
      data: privileged_user(user),
      authn_token: token
    }
  end
  def register(%{user: user}), do: %{data: privileged_user(user)}

  def forgot_password(_), do: %{messages: ["If the account exists, we've sent an email."]}
  def reset_password(_), do: %{messages: ["Successfully reset password."]}
  def confirm_email(_), do: %{messages: ["Successfully confirmed email."]}
  def resend_confirmation(_), do: %{messages: ["If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."]}

  defp privileged_user(user), do: Map.take(user, [:id, :username, :email, :confirmed_at])
end
