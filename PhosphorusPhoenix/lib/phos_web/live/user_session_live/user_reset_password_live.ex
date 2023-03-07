defmodule PhosWeb.UserResetPasswordLive do
  use PhosWeb, :live_view

  alias Phos.Users

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen justify-center items-center">
      <.header class="text-center">Reset Password</.header>

      <.simple_form
        :let={f}
        class="w-94 p-4"
        for={@changeset}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.error :if={@changeset.action == :insert}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={{f, :password}} type="password" label="New password" required />
        <.input
          field={{f, :password_confirmation}}
          type="password"
          label="Confirm new password"
          required
        />
        <:actions>
          <.button phx-disable-with="Resetting..." type="submit">Reset Password</.button>
        </:actions>
      </.simple_form>

      <div class="text-base   dark:text-white flex gap-4">
        <.link navigate={~p"/users/register"} class="text-sm text-teal-400 font-bold hover:underline">
          Register
        </.link>
        <.link navigate={~p"/users/log_in"} class="text-sm text-teal-400 font-bold hover:underline">
          Log in
        </.link>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    socket =
      case socket.assigns do
        %{user: user} ->
          assign(socket, :changeset, Users.change_user_password(user))

        _ ->
          socket
      end

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Users.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Users.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Users.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end
end
