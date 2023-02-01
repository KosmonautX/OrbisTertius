defmodule PhosWeb.UserForgotPasswordLive do
  use PhosWeb, :live_view

  alias Phos.Users

  def render(assigns) do
    ~H"""
    <div class="w-full flex flex-col justify-center h-screen items-center">
      <.header class="text-center">
        Forgot your password?
        <:subtitle>We'll send a password reset link to your inbox</:subtitle>
      </.header>

      <.simple_form :let={f} id="reset_password_form" for={:user} phx-submit="send_email">
        <.input field={{f, :email}} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full" type="submit">
            Send password reset instructions
          </.button>
        </:actions>
      </.simple_form>
      <div class="mt-3 text-sm text-gray-500 ">
        <.link patch={~p"/users/register"} )} class="text-sm text-teal-400 font-bold hover:underline">
          Sign up
        </.link>
        Or
        <.link patch={~p"/users/log_in"} class="text-sm text-teal-400 font-bold hover:underline">
          Sign in
        </.link>
        via Web
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Users.get_user_by_email(email) do
      Users.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
