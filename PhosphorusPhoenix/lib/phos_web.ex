defmodule PhosWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PhosWeb, :controller
      use PhosWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths(), do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: PhosWeb,
        formats: [:html, :json],
        layouts: [html: PhosWeb.Layouts]

      import Plug.Conn
      import PhosWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PhosWeb.Layouts, :app}

      import PhosWeb.UserPresence

      unquote(html_helpers())
    end
  end

  def admin_view do
    quote do
      use Phoenix.LiveView,
        layout: {PhosWeb.Layouts, :admin}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel, log_join: :debug
      import PhosWeb.Util.Authorization
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller, only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  def view do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.Component
      # import PhosWeb.LiveHelpers
      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View
      import PhosWeb.CoreComponents
      import PhosWeb.Gettext
      alias Phoenix.LiveView.JS

      def transition(from, to) do
        %{
          id: Ecto.UUID.generate(),
          "phx-hook": "TransitionHook",
          "data-transition-from": from,
          "data-transition-to": to
        }
      end

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PhosWeb.Endpoint,
        router: PhosWeb.Router,
        statics: PhosWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
