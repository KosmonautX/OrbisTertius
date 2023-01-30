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

      <.simple_form class="w-96 p-4"
        :let={f}
        id="login_form"
        for={:user}
        action={~p"/users/log_in"}
        as={:user}
        phx-update="ignore"
      >
        <.input field={{f, :email}} type="email" label="Email" required />
        <.input field={{f, :password}} type="password" label="Password" required />
        <.input field={{f, :return_to}} type="hidden" label="return_to" value={@return_to} />
    

        <:actions :let={f}>
          <.input field={{f, :remember_me}} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Sigining in..." class="w-full" type="submit">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    IO.inspect(params)
    {:ok,
      assign(socket, email: email)
      |> assign_new(:return_to, fn -> Map.get(params, "return_to") end),
      temporary_assigns: [email: nil]}
  end
end
