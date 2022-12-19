# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :phos,
  ecto_repos: [Phos.Repo]

# Configures the endpoint
config :phos, PhosWeb.Endpoint,
  url: [host: "localhost"], #change to "127.0.0.1" to work on privelleged port 80
  render_errors: [
    formats: [html: PhosWeb.ErrorHTML, json: PhosWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Phos.PubSub,
  live_view: [signing_salt: "r193MsgJ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.

config :phos, Phos.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
# config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args: ~w(js/app.js js/admin.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
#config :phoenix, :filter_parameters, ["token"]

config :phos, Phos.OAuthStrategy,
  google: [
    client_id: {System, :get_env, ["GOOGLE_CLIENT_ID"]},
    client_secret: {System, :get_env, ["GOOGLE_CLIENT_SECRET"]},
    strategy: Assent.Strategy.Google,
    http_adapter: Assent.HTTPAdapter.Mint
  ],
  apple: [
    team_id: {System, :get_env, ["APPLE_TEAM_ID"]},
    client_id: {System, :get_env, ["APPLE_CLIENT_ID"]},
    private_key: {System, :get_env, ["APPLE_PRIVATE_KEY"]}, # use either private_key or private_key path
    private_key_id: {System, :get_env, ["APPLE_PRIVATE_KEY_ID"]},
    # private_key_path: {System, :get_env, ["APPLE_PRIVATE_KEY_PATH"]}, # Use either private_key or private_key_path
    strategy: Assent.Strategy.Apple,
    http_adapter: Assent.HTTPAdapter.Mint
  ],
  telegram: [
    host: {System, :get_env, ["TELEGRAM_REDIRECT_HOST"]}, # https://endpoint.com
    bot_id: {System, :get_env, ["TELEGRAM_BOT_ID"]},
  ]

config :tailwind, version: "3.1.6",
  admin: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/admin.css
      --output=../priv/static/assets/admin.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ],
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :phos, Phos.Cache,
  primary: [
    gc_interval: :timer.hours(12),
    backend: :shards,
    partitions: 2
  ]

config :fcmex,
  [json_library: Jason]

config :phos, Phos.External.Notion,
  token: {System, :get_env, "NOTION_TOKEN"},
  database: {System, :get_env, "NOTION_DATABASE"},
  notification_database: {System, :get_env, "NOTION_NOTIFICATION_DATABASE"}

config :phos, Phos.Admin,
  password: System.get_env("ADMIN_TUNNEL"),
  algorithm: :sha256

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
