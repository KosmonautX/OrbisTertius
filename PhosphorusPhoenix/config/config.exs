# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :phos, Phos.TeleBot.Cache,
  # When using :shards as backend
  # backend: :shards,
  # GC interval for pushing new generation: 12 hrs
  gc_interval: :timer.hours(12),
  # Max 1 million entries in cache
  max_size: 1_000_000,
  # Max 2 GB of memory
  allocated_memory: 2_000_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC max timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

config :phos,
  ecto_repos: [Phos.Repo]

# Configures the endpoint
config :phos, PhosWeb.Endpoint,
  # change to "127.0.0.1" to work on privelleged port 80
  url: [host: "localhost"],
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
config :swoosh,
  api_client: Swoosh.ApiClient.Finch,
  finch_name: Swoosh.Finch

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js js/admin.js js/storybook.js vendor/fonts/Poppins/poppins.css --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --loader:.woff2=file --loader:.woff=file),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :default_handler,
  level: :debug

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
# config :phoenix, :filter_parameters, ["token"]

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
    # use either private_key or private_key path
    private_key: {System, :get_env, ["APPLE_PRIVATE_KEY"]},
    private_key_id: {System, :get_env, ["APPLE_PRIVATE_KEY_ID"]},
    # private_key_path: {System, :get_env, ["APPLE_PRIVATE_KEY_PATH"]}, # Use either private_key or private_key_path
    strategy: Assent.Strategy.Apple,
    http_adapter: Assent.HTTPAdapter.Mint
  ],
  telegram: [
    host: {System, :get_env, ["TELEGRAM_REDIRECT_HOST"]}, #"5fba-220-255-157-189.ngrok-free.app/telegram_signup",
    bot_id: {System, :get_env, ["TELEGRAM_BOT_ID"]}
  ]

config :tailwind,
  version: "3.3.3",
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
  ],
  storybook: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/storybook.css
      --output=../priv/static/assets/storybook.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :phos, Phos.Cache,
  primary: [
    gc_interval: :timer.hours(12),
    backend: :shards,
    partitions: 2
  ]

config :phos, Phos.TeleBot.Cache,
  primary: [
    gc_interval: :timer.hours(12),
    backend: :shards,
    partitions: 2
  ]

config :fcmex,
  json_library: Jason

config :phos, Phos.TeleBot.Core,
  callback_url: {PhosWeb.Router.Helpers, :telegram_url, [PhosWeb.Endpoint, :create]}, #"//5fba-220-255-157-189.ngrok-free.app/bot/telegram_signup",
  bot_token: {System, :get_env, ["TELEGRAM_BOT_ID"]}

config :phos, Phos.External.Notion,
  token: {System, :get_env, "NOTION_TOKEN"},
  database: {System, :get_env, "NOTION_DATABASE"},
  orb_database: "b47fc73f3c054c10a2b74296937cdfb4",
  article_database: "6f552e97275f453ba4edee2c3a532c0f",
  notification_database: {System, :get_env, "NOTION_NOTIFICATION_DATABASE"}

config :phos, Phos.PlatformNotification,
  worker: 18,
  time_interval: 3,
  min_demand: 5,
  max_demand: 8

config :phos, Phos.TeleBot.TelegramNotification,
  worker: 8,
  time_interval: 3,
  min_demand: 2,
  max_demand: 5

# config :sparrow,
#   pool_enabled: true,
#   fcm: [
#     [
#       path_to_json: Path.expand("../priv/data/sparrow-config.json", __DIR__)
#     ]
#   ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

config :phos, Phos.Models.OpenAI,
  model: "text-davinci-003",
  # token: {System, :fetch_env, "OPENAI_KEY"}
  token: "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"


config :phos, Phos.Oracle,
  textembedder: [
  source: :hf,
  model: "thenlper/gte-base"
  ]

import_config "#{config_env()}.exs"
