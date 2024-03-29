defmodule PhosWeb.Router do
  use PhosWeb, :router

  import PhosWeb.Menshen.Gate
  import PhosWeb.Menshen.Plug
  import Phoenix.LiveDashboard.Router
  import PhxLiveStorybook.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhosWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    # plug PhosWeb.Menshen.Mounter, :pleb
  end

  pipeline :apple_callback do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhosWeb.Layouts, :root}
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :put_root_layout, {PhosWeb.Layouts, :admin_root}
    plug Phos.Admin.Plug
  end

  scope "/" do
    storybook_assets()
  end

  ## Home Page & Public Pages
  scope "/", PhosWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/redirect/:out", PageController, :redirect

    live_storybook("/storybook", backend_module: PhosWeb.Storybook)
  end

  ## User Genesis Routes
  scope "/", PhosWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PhosWeb.Menshen.Gate, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end
    post "/users/log_in", UserSessionController, :create
  end

  scope "/", PhosWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :onboarding_user,
      on_mount: [{PhosWeb.Menshen.Gate, :mount_current_user}] do
      live "/begin", UserWelcomeLive, :onboard
    end


    live_session :required_authenticated_user,
      on_mount: [{PhosWeb.Menshen.Gate, :ensure_authenticated}, {PhosWeb.Menshen.Mounter, :timezone}] do

      live "/welcome", UserWelcomeLive, :welcome

      live "/orb/article", OrbLive.Article, :index
      live "/orb/search", OrbLive.Search, :index
      live "/orb/news", OrbLive.News, :index

      live "/orb/:id/show/:cid", OrbLive.Show, :show_ancestor
      live "/orb/:id/reply/:cid", OrbLive.Show, :reply
      live "/orb/:id/edit/:cid", OrbLive.Show, :edit_comment

      live "/user/feeds", UserFeedLive.Index, :index

      live "/user/:username/edit", UserProfileLive.Show, :edit

      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/memories", MemoryLive.Index, :index
      live "/memories/new", MemoryLive.Index, :new
      live "/memories/user/:username", MemoryLive.Index, :show
      live "/memories/media/:id", MemoryLive.Index, :media
    end
  end

  scope "/admin", PhosWeb.Admin, as: :admin, on_mount: {Phos.Admin.Mounter, :admin} do
    pipe_through [:browser, :admin]

    live_dashboard "/dashboard",
      metrics: PhosWeb.Telemetry,
      ecto_repos: [Phos.Repo],
      ecto_psql_extras_options: [long_running_queries: [threshold: "200 milliseconds"]]

    live "/", DashboardLive, :index
    live "/orbs", OrbLive.Index, :index
    live "/orbs/import", OrbLive.Import, :imports
    live "/orbs/:id", OrbLive.Show, :show

    live "/users", UserLive.Index, :index
    live "/users/:page", UserLive.Index, :index
    live "/users/:id/edit", UserLive.Index, :edit

    live "/leaderboard", LeaderboardLive.Index, :user
    live "/leaderboard/orb", LeaderboardLive.Index, :orb

    live "/notifications", NotificationLive.Index, :index

    live "/articles", ArticleLive.Index, :index
    live "/articles/scoops", ArticleLive.Scoop, :index
    live "/articles/scoops/:id", ArticleLive.ScoopDetail, :show
  end

  scope "/api", PhosWeb.API do
    # firebased auth
    # , error_handler:
    pipe_through [:api]

    get "/version/:version", FyrAuthController, :semver

    scope "/userland" do
      scope "/auth/fyr" do
        get "/", FyrAuthController, :transmute
        # Create User
        post "/genesis", FyrAuthController, :genesis
      end
    end
  end

  scope "/api", PhosWeb.API do
    pipe_through [:api, :authorized_user]

    scope "/userland" do
      get "/self", UserProfileController, :show_self
      put "/self", UserProfileController, :update_self
      put "/self/territory", UserProfileController, :update_territory
      put "/self/beacon", UserProfileController, :update_beacon
      get "/others/:id", UserProfileController, :show
      get "/self/activity", EchoController, :show_activity

      get "/others/:id/history", OrbController, :show_history
      put "/others/:id/report", TribunalController, :report_user

      scope "/auth/email" do
        post "/login", AuthNEmailController, :login
        post "/register", AuthNEmailController, :register
        post "/confirm_email", AuthNEmailController, :confirm_email
        get "/resend_confirmation", AuthNEmailController, :resend_confirmation
        post "/forgot_password", AuthNEmailController, :forgot_password
        post "/reset_password", AuthNEmailController, :reset_password
      end
    end

    get "/orbland/stream/:id", OrbController, :show_territory
    resources "/orbland/orbs", OrbController, except: [:new, :edit]
    put "/orbland/orbs/:orb_id/blorbs", BlorbController, :create
    put "/orbland/orbs/:orb_id/blorbs/:id", BlorbController, :update
    delete "/orbland/orbs/:orb_id/blorbs/:id", BlorbController, :delete
    put "/orbland/orbs/:id/report", TribunalController, :report_orb

    resources "/orbland/comments", CommentController, except: [:new, :edit]
    get "/orbland/comments/root/:id", CommentController, :show_root
    get "/orbland/comments/children/:id", CommentController, :show_children
    get "/orbland/comments/ancestor/:id", CommentController, :show_ancestor
    put "/orbland/comments/root/:id/report", TribunalController, :report_comment

    scope "/folkland" do
      get "/stream/self", OrbController, :show_friends
      get "/stream/discovery/:id", FriendController, :show_discovery
      get "/others/:id", FriendController, :show_others
      put "/friends/block", FriendController, :block
      put "/friends/accept", FriendController, :accept
      get "/self/requests", FriendController, :requests
      get "/self/pending", FriendController, :pending
      get "/self/blocked", FriendController, :blocked
      resources "/friends", FriendController, except: [:new, :edit, :update]
    end

    scope "/memland" do
      resources "/memories", EchoController, except: [:new, :edit]
      put "/reveries/:id", EchoController, :update_reverie
      get "/friends", FriendController, :index_last_memories
      get "/orbs/:id", EchoController, :show_orbs
      # get "/assemblies", TerraController, :index_last_assemblies
      get "/territories/:id", EchoController, :show_territories
      get "/friends/:id", EchoController, :show_relations
      get "/friends/:id/orbs", EchoController, :show_relations_jump_orbs
    end

    scope "/medialand" do
      post "/media/:archetype/:id", MediaController, :show
    end
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

  scope "/telegram", PhosWeb do
    post "/:token", TelegramController, :webhook
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).

  # if Mix.env() in [:dev, :test] do
  #   import Phoenix.LiveDashboard.Router

  #   scope "/" do
  #     pipe_through :browser

  #     live_dashboard "/dashboard", metrics: PhosWeb.Telemetry
  #   end
  # end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/api/devland", PhosWeb.API do
      pipe_through :api

      get "/flameon", DevLandController, :new
      get "/lankaonfyr", DevLandController, :fyr
    end
  end

  if Mix.env() == :test or Mix.env() == :dev do
    scope "/", PhosWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :required_authenticated_user_dev,
        on_mount: [{PhosWeb.Menshen.Gate, :ensure_authenticated},{PhosWeb.Menshen.Mounter, :timezone}] do
        live "/orb", OrbLive.Index, :index
        live "/orb/new", OrbLive.Index, :new
        live "/orb/sethome", OrbLive.Index, :sethome
        live "/orb/setwork", OrbLive.Index, :setwork

        live "/orb/:id/edit", OrbLive.Index, :edit
        live "/orb/:id/show/edit", OrbLive.Show, :edit
      end
    end
  else
    scope "/", PhosWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :required_authenticated_user_dev,
        on_mount: [{PhosWeb.Menshen.Gate, :ensure_authenticated},{PhosWeb.Menshen.Mounter, :timezone}] do
        get "/orb", ErrorController, :_404

        get "/orb/new", ErrorController, :_404
        get "/orb/sethome", ErrorController, :_404
        get "/orb/setwork", ErrorController, :_404

        get "/orb/:id/edit", ErrorController, :_404
        get "/orb/:id/show/edit", ErrorController, :_404
      end
    end
  end

  scope "/", PhosWeb do
    pipe_through [:browser]

    resources "/admin/sessions", AdminSessionController,
      only: [:new, :create, :index],
      as: :admin_session

    get "/users/log_out", UserSessionController, :delete

    get "/bot/telegram_signup", TelegramController, :create

    live_session :current_user,
      on_mount: [{PhosWeb.Menshen.Gate, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirmtg/:token", UserConfirmationLive, :edit_tg
      live "/users/confirm", UserConfirmationInstructionsLive, :new
      live "/users/bind/telegram/:token", UserConfirmationLive, :bind_telegram
    end

    live_session :guest_if_not_logged_in,
      on_mount: [{PhosWeb.Menshen.Gate, :ensure_authenticated}, {PhosWeb.Menshen.Mounter, :timezone}] do

      live "/orb/:id", OrbLive.Show, :show
      live "/user/:username", UserProfileLive.Show, :show
      live "/user/:username/allies", UserProfileLive.Index, :allies
    end
  end
end
