defmodule PhosWeb.Router do
  use PhosWeb, :router

  import PhosWeb.Menshen.Gate
  import PhosWeb.Menshen.Plug
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhosWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    #plug PhosWeb.Menshen.Mounter, :pleb
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

  ## Home Page & Public Pages
  scope "/", PhosWeb do
    pipe_through :browser

    get "/", PageController, :home
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
    pipe_through [:browser]

    resources "/admin/sessions", AdminSessionController, only: [:new, :create, :index], as: :admin_session

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PhosWeb.Menshen.Gate, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end


  scope "/", PhosWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :required_authenticated_user,
      on_mount: {PhosWeb.Menshen.Gate, :ensure_authenticated} do
      get "/", PageController, :index
      # get "/orb/sethome", OrbLiveController, :set_home
      # get "/orb/setwork", OrbLiveController, :set_work
      # resources "/orb", OrbLiveController, only: [:index, :show]

      live "/orb/sethome", OrbLive.Index, :sethome
      live "/orb/setwork", OrbLive.Index, :setwork

      live "/orb", OrbLive.Index, :index
      live "/orb/new", OrbLive.Index, :new
      live "/orb/:id/edit", OrbLive.Index, :edit

      live "/orb/:id", OrbLive.Show, :show
      live "/orb/:id/show/edit", OrbLive.Show, :edit
      live "/orb/:id/show/:cid", OrbLive.Show, :show_ancestor
      live "/orb/:id/reply/:cid", OrbLive.Show, :reply
      live "/orb/:id/edit/:cid", OrbLive.Show, :edit_comment

      live "/user/feeds", UserFeedLive.Index, :index

      live "/user/:username/edit", UserProfileLive.Show, :edit
      live "/user/:username", UserProfileLive.Show, :show

      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email


      live "/memories", MemoryLive.Index, :index
      live "/memories/new", MemoryLive.Index, :new
      live "/memories/:id/edit", MemoryLive.Index, :edit

      live "/memories/:id", MemoryLive.Show, :show
      live "/memories/:id/show/edit", MemoryLive.Show, :edit


      live "/reveries", ReverieLive.Index, :index
      live "/reveries/new", ReverieLive.Index, :new
      live "/reveries/:id/edit", ReverieLive.Index, :edit

      live "/reveries/:id", ReverieLive.Show, :show
      live "/reveries/:id/show/edit", ReverieLive.Show, :edit



    end
  end

  scope "/admin", PhosWeb.Admin, as: :admin, on_mount: {Phos.Admin.Mounter, :admin} do
    pipe_through [:browser, :admin]

    live_dashboard "/dashboard", metrics: PhosWeb.Telemetry
    live "/", DashboardLive, :index
    live "/orbs", OrbLive.Index, :index
    live "/orbs/import", OrbLive.Import, :import
    live "/orbs/:id", OrbLive.Show, :show
  end

  scope "/api", PhosWeb.API do
    #firebased auth
    pipe_through [:api] # , error_handler:

    get "/version/:version", FyrAuthController, :semver

    scope "/userland" do

      scope "/auth/fyr" do
        get "/", FyrAuthController, :transmute
        post "/genesis", FyrAuthController, :genesis # Create User
      end
    end
    # get "/", AuthController, :index
    # patch "/", AuthController, :update
    # post "/login", AuthController, :login
    # post "/register", AuthController, :register
    # post "/confirm_email", AuthController, :confirm_email
    # post "/forgot_password", AuthController, :forgot_password
    # post "/reset_password", AuthController, :reset_password

  end

  scope "/api", PhosWeb.API do
    pipe_through [:api, :authorized_user]


    get "/userland/self", UserProfileController, :show_self
    put "/userland/self", UserProfileController, :update_self
    put "/userland/self/territory", UserProfileController, :update_territory
    put "/userland/self/beacon", UserProfileController, :update_beacon
    get "/userland/others/:id", UserProfileController, :show

    get "/userland/others/:id/history", OrbController, :show_history


    get "/orbland/stream/:id", OrbController, :show_territory
    resources "/orbland/orbs", OrbController, except: [:new, :edit]

    resources "/orbland/comments", CommentController, except: [:new, :edit]
    get "/orbland/comments/root/:id", CommentController, :show_root
    get "/orbland/comments/children/:id", CommentController, :show_children
    get "/orbland/comments/ancestor/:id", CommentController, :show_ancestor

    scope "/folkland" do
      get "/stream/self", OrbController, :show_friends
      get "/stream/discovery/:id", FriendController, :show_discovery
      get "/others/:id", FriendController, :show_others
      put "/friends/block", FriendController, :block
      put "/friends/accept", FriendController, :accept
      get "/self/requests", FriendController, :requests
      get "/self/pending", FriendController, :pending
      resources "/friends", FriendController, except: [:new, :edit, :update]
    end

    scope "/memland" do
      resources "/memories", EchoController, except: [:new, :edit]
      get "/orbs", EchoController, :index_orbs
      get "/friends", EchoController, :index_relations
      get "/orbs/:id", EchoController, :show_orbs
      get "/friends/:id", EchoController, :show_relations
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
 end
