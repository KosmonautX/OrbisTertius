import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :phos, Phos.Repo,
  username: System.get_env("PGUSERNAME") || "postgres",
  password: "root",
  hostname: "localhost",
  database: "phos_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  types: Phos.PostgresTypes

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phos, PhosWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "NRTzFDzWqImIKzzOJLr/6yHsEdoQt6OMJDF9ee5+Uv7CZmFUxwWS2qg1MAtvuWtT",
  server: false

# In test we don't send emails.
config :phos, Phos.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn
# config :logger, level: :debug

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

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
    host: "http://localhost:4002",
    botname: "telegram_bot_name"
  ]

config :ex_aws, :retries,
  max_attempts: 0,
  base_backoff_in_ms: 10,
  max_backoff_in_ms: 10_000
