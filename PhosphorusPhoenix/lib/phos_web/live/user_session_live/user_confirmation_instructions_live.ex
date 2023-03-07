defmodule PhosWeb.UserConfirmationInstructionsLive do
  use PhosWeb, :live_view

  alias Phos.Users

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen justify-center items-center">
      <.header>Resend confirmation instructions</.header>

      <.simple_form :let={f} for={:user} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={{f, :email}} type="email" label="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." type="submit">
            Resend confirmation instructions
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-gray-600 font-bold mt-2">
        <.link href={~p"/users/register"} class="font-semibold text-base text-teal-500 underline">
          Register
        </.link>
        Or
        <.link href={~p"/users/log_in"} class="font-semibold text-base text-teal-500 underline">
          Log in
        </.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Users.get_user_by_email(email) do
      Users.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
