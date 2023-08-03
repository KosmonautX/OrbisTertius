defmodule PhosWeb.UserConfirmationLive do
  use PhosWeb, :live_view

  alias Phos.Users

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="flex flex-col h-screen justify-center items-center">
      <.header>Confirm Account</.header>

      <.simple_form class="max-w-2xl p-4 space-y-4 rounded-2xl mt-4"
       :let={f} for={%{}} as={:user} id="confirmation_form" phx-submit="confirm_account">
        <.input field={{f, :token}} type="hidden" value={@token} />
        <:actions>
          <.button phx-disable-with="Confirming..." type="submit">Confirm my account</.button>
        </:actions>
      </.simple_form>
      <p class="text-gray-600 font-bold mt-2 hidden">
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

  def render(%{live_action: :edit_tg} = assigns) do
    ~H"""
    <%!-- <.confirm_card
      on_confirm={}
    >
      <:confirm>Confirm Account</:confirm>
    </.confirm_card> --%>

    <div
      class="absolute inset-0 bg-gray-700 bg-opacity-70 flex flex-col justify-center items-center space-y-4"
      >
      <h1 class="mt-4 text-xl md:text-4xl text-center font-bold tracking-tight text-white">
      <.header>Confirm Account</.header>
        <.simple_form class="max-w-2xl p-4 space-y-4 rounded-2xl mt-4"
          :let={f} for={%{}} as={:user} id="confirmation_form" phx-submit="confirm_account_tg">
          <.input field={{f, :token}} type="hidden" value={@token} />
          <:actions>
            <.button phx-disable-with="Confirming..." type="submit">Confirm my account</.button>
          </:actions>
        </.simple_form>
        <p class="text-gray-600 font-bold mt-2 hidden">
          <.link href={~p"/users/register"} class="font-semibold text-base text-teal-500 underline">
            Register
          </.link>
          Or
          <.link href={~p"/users/log_in"} class="font-semibold text-base text-teal-500 underline">
            Log in
          </.link>
        </p>
      </h1>
    </div>
    """
  end

  def render(%{live_action: :bind_telegram} = assigns) do
    ~H"""
    <img
    class="object-cover h-screen w-full"
    src="/images/user_splash.jpg"
    alt="Background Image"
    />
    <div class="flex flex-col h-screen justify-center items-center">
      <.header>Confirm Link</.header>

      <.simple_form :let={f} for={%{}} as={:user} id="bind_account_form" phx-submit="bind_account">
        <.input field={{f, :token}} type="hidden" value={@token} />
        <:actions>
          <.button phx-disable-with="Linking..." type="submit">Link my account</.button>
        </:actions>
      </.simple_form>
      <p class="text-gray-600 font-bold mt-2 hidden">
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

  def mount(params, _session, socket) do
    {:ok, assign(socket, token: params["token"]), temporary_assigns: [token: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Users.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end

  def handle_event("confirm_account_tg", %{"user" => %{"token" => token}}, socket) do
    case Users.confirm_user(token) do
      {:ok, %{integrations: %{telegram_chat_id: telegram_id}} = user} ->
        ExGram.send_message(telegram_id, "Your account has been confirmed successfully! You can now /post")
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("bind_account", %{"user" => %{"token" => token}}, socket) do
    case Users.bind_user(token) do
      {:ok, %{integrations: %{telegram_chat_id: telegram_id}} = user} ->
        ExGram.send_message(telegram_id, "Your account has been binded successfully! You can now /post")
        {:noreply,
         socket
         |> put_flash(:info, "Telegram Binded successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "Telegram bind confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
