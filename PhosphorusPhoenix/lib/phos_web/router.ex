defmodule PhosWeb.Router do
  use PhosWeb, :router

  import PhosWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhosWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :apple_callback do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhosWeb.LayoutView, :root}
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authentication do
  end

  pipeline :admin do
    plug :put_root_layout, {PhosWeb.LayoutView, :admin_root}
    plug Phos.Admin.Plug
  end

  scope "/", PhosWeb do
    pipe_through [:browser, :authentication]

    get "/archetype", ArchetypeController, :show do
      resources "/archetype/usr", UserController, only: [:show]
    end

    live_session :authenticated, on_mount: {PhosWeb.Menshen.Mounter, :pleb} do
      get "/", PageController, :index

      live "/orb/sethome", OrbLive.Index, :sethome
      live "/orb/setwork", OrbLive.Index, :setwork

      live "/orb", OrbLive.Index, :index
      live "/orb/new", OrbLive.Index, :new
      live "/orb/:id/edit", OrbLive.Index, :edit

      live "/orb/:id", OrbLive.Show, :show
      live "/orb/:id/show/edit", OrbLive.Show, :edit
    end
  end

  scope "/admin", PhosWeb.Admin, as: :admin, on_mount: {Phos.Admin.Mounter, :admin} do
    pipe_through [:browser, :admin]

    live "/", DashboardLive, :index
    live "/orbs", OrbLive.Index, :index
    live "/orbs/:id", OrbLive.Show, :show
  end

  # Other scopes may use custom stacks.
  scope "/auth", PhosWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  scope "/auth", PhosWeb do
    pipe_through :apple_callback

    post "/telegram/callback", AuthController, :telegram_callback
    post "/:provider/callback", AuthController, :apple_callback
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PhosWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PhosWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", PhosWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", PhosWeb do
    pipe_through [:browser]

    resources "/admin/sessions", Admin.SessionController, only: [:new, :create, :index], as: :admin_session

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
