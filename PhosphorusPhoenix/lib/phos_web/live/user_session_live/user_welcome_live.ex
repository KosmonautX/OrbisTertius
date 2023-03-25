defmodule PhosWeb.UserWelcomeLive do
  use PhosWeb, :live_view

  alias Phos.Users
  import PhosWeb.SVG

  def render(assigns) do
    ~H"""
    <div class="flex flex-col  h-screen justify-center items-center space-y-4 text-gray-600">
      <h2 class="md:text-3xl text-2xl font-bold max-w-md text-center dark:text-white">
        <%= "Welcome to the tribe, #{@current_user.username}!" %>
      </h2>
      <div :if={is_nil(@current_user.username)}>
        <.header>Choose your Username</.header>
        <.simple_form
          :let={f}
          class="w-96 p-4"
          id="email_form"
          for={@username_changeset}
          phx-submit="update_username"
          phx-change="validate_username"
        >
          <.error :if={@username_changeset == :insert}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <.input field={{f, :username}} type="text" label="Username" required />

          <:actions>
            <.button phx-disable-with="Anointing..." type="submit">Submit Choice</.button>
          </:actions>
        </.simple_form>
      </div>

      <div
        :if={!is_nil(@current_user.username)}
        class="flex flex-col justify-center items-center space-y-4 text-gray-600"
      >
        <h3 class="md:text-2xl text-xl font-bold max-w-md text-center dark:text-gray-400">
          You’re all set for now.
        </h3>
        <.logo class="h-36 w-36 dark:fill-white"></.logo>
        <p class="max-w-md text-center text-base font-medium dark:text-gray-200">
          You’ll need to download the app to access all features. But for now, you’re set to do what you were about to do!
        </p>
        <a href="https://play.google.com/store/apps/details?id=com.scratchbac.baladi" target="_blank">
          <.button type="submit">Download the Scratchbac App</.button>
        </a>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:username_changeset, Users.change_user_username(user))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_username", params, socket) do
    %{"user" => %{"username" => username}} = params

    username_changeset =
      Users.change_user_username(socket.assigns.current_user, %{username: username})

    socket =
      assign(socket,
        username_changeset: Map.put(username_changeset, :action, :validate)
      )

    {:noreply, socket}
  end

  def handle_event("update_username", params, socket) do
    %{"user" => %{"username" => username}} = params
    user = socket.assigns.current_user

    case Users.update_pub_user(user, %{"username" => username}) do
      {:ok, _} ->
        info = "Username Chosen"
        {:noreply, socket |> put_flash(:info, info) |> redirect(to: ~p"/welcome")}

      {:error, changeset} ->
        {:noreply, assign(socket, :username_changeset, Map.put(changeset, :action, :insert))}
    end
  end
end
