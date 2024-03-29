defmodule PhosWeb.UserRegistrationLive do
  use PhosWeb, :live_view

  alias Phos.Users
  alias Phos.Users.User

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen  justify-center items-center">
      <.header class="text-center">
      Join the Tribe!
        <:subtitle>
        Already have an account?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          here.
        </:subtitle>
      </.header>

      <.simple_form class="max-w-2xl p-4 space-y-4 rounded-2xl mt-4"
        :let={f}
        id="registration_form"
        for={@changeset}
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
        as={:user}
      >
        <.error :if={@changeset.action == :insert}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={{f, :return_to}} type="hidden" value={@return_to} />
        <.input field={{f, :email}} type="email" label="Email" required />
        <.input field={{f, :username}} label="Username" required />
        <.input field={{f, :password}} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full" type="submit">Create account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(params, _session, socket) do
    changeset = Users.change_user_registration(%User{})

    socket =
      assign(socket, changeset: changeset, trigger_submit: false)
      |> assign_new(:return_to, fn -> Map.get(params, "return_to", ~p"/welcome") end)

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Users.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Users.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Users.change_user_registration(user)
        {:noreply, assign(socket, trigger_submit: true, changeset: changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Users.change_user_registration(%User{}, user_params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end
end
