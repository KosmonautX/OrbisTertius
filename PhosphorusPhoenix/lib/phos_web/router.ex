defmodule PhosWeb.Router do
  use PhosWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhosWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhosWeb do
    pipe_through :browser

    get "/archetype", ArchetypeController, :show do
      resources "/archetype/usr", UserController, only: [:show]
    end

    get "/auth/:provider", AuthController, :request
    get "/auth/:provider/callback", AuthController, :callback

    live "/orb/sethome", OrbLive.Index, :sethome
    live "/orb/setwork", OrbLive.Index, :setwork

    live "/orb", OrbLive.Index, :index
    live "/orb/new", OrbLive.Index, :new
    live "/orb/:id/edit", OrbLive.Index, :edit

    live "/orb/:id", OrbLive.Show, :show
    live "/orb/:id/show/edit", OrbLive.Show, :edit

    live "/sign_up", SignUpLive.Index, :index

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhosWeb do
  #   pipe_through :api
  # end

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
end
