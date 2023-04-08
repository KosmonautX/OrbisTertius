defmodule PhosWeb.UserLoginLive do
  use PhosWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen justify-center items-center">
      <.header class="text-center">
        Sign in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form
        :let={f}
        class="w-108 p-4"
        id="login_form"
        for={:user}
        action={~p"/users/log_in"}
        as={:user}
        phx-update="ignore"
      >
        <.input field={{f, :email}} type="email" label="Email" required />
        <.input field={{f, :password}} type="password" label="Password" required />
        <.input field={{f, :return_to}} type="hidden" value={@return_to} />
        <:actions :let={f} classes="relative h-12 w-108">
          <.input field={{f, :remember_me}} type="checkbox" label="Remember Me?" />
          <.link href={~p"/users/reset_password"} class="absolute bottom-0 right-0 text-sm font-semibold dark:text-white">
            Forgot your password?
          </.link>
        </:actions>

        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full" type="submit">
            Sign in <span aria-hidden="true"></span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    {:ok,
     assign(socket, email: email)
     |> assign_new(:return_to, fn -> Map.get(params, "return_to", "/welcome") end),
     temporary_assigns: [email: nil]}
  end
end
