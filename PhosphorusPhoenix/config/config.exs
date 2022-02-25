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
  url: [host: "localhost"],
  render_errors: [view: PhosWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Phos.PubSub,
  live_view: [signing_salt: "r193MsgJ"]

  # %{
#   "projectId" => "scratchbac-v1-ee11a", #System.get_env("FYR_PROJ"),
#   "privateKey" => "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCLEedLz1OIp/EH\nrNdy0tUFqkmNaE0M31ii5Gu0NM/JF40DcVX4VqzMjiQyqrVOFzesBDLzGFERMoAY\ndzU+D2zQSaCsEgJC/yUgDgOQnnZUcYtH2GFacS/SHJZfS5RgAaB86CIO4Z7boh+3\np5D3/aEOSHP1cE7pqydsGgxmyRlRybTBO/Qike0fr4Cd4vk5CLz7Ng5Ibr8xSeGP\n4v3Z9GzRLNgwLmPcEFoF76QgSmAtXGb7bQOwIzp1S4kwgWXOeGhNmt13aHyfgaZK\nL4wk4Dg8pMtHXqRfMLxUxhCT30/BWuaJQl0MH/80A712fLEF+Kz5DnveEArgtSeK\nL1+SN8WZAgMBAAECggEAAY8LPhIAjNWSxlQbDhtHbkGup6f1oI8GB5jOH6vSJ0KU\nCAxrKNZJA0MVvn8Rn3UGBUtH5cWk3B1X71v7RRQ8UyOgIR/l+pdnz/q8zccGoaes\nJo23wsXBb792SATf/k3GXU3Cf2VYk1db3DkfKpGQ6f/IwYWCvOxTnjiSPLppc6s3\nKikEKrXrZXEpCkp7tg1uqiMBv70LXXBIYRv9tQZipt2H/DxlPwAYciF19q29rxHK\nhxGA/adLnrgV1/z6ry2Ttpoc0KlzypeF+9L6J8vn4jtu5TkJZmfk01aCRhCgKjSN\nqBOXF5s6oSTFeu+XtNV8n5CtyUDgYuvnAJJyfBeCKQKBgQDCO5tchEmd4mZ8mJBE\n9PMchYiqHE68LVDDah2Or8z9wT+MA+KVAvDITolmLRcbqBNL5gikmQ7760JDi4Ts\nK4EyK2+DxDDqfHIhPCdv7WychMxzpb2zhnwvteRzbXXsJ8kb9HZfzO3bESXwwm/W\n3H9s6I2aVcJya7DXpdVqw+66KwKBgQC3S4OAtllMkwWi7hb1zAARhlIfmyuTbQuA\noxpiKjisQvGU16Bs+uiZZ3m5q2mB+RJhx2qGN4oXmfiMBDBqpV0pU2suHcQCPWMo\nrhuIrgVLULotYiATl6HMg9SbDuXfrQjUBS12G9Xa650POE5yD15BlvhLgDS6e0nw\niSLSw28xSwKBgE4LH1DcQqwy1RVJQ+bBOZIDQbeAak6IMsRiNgAoOUjYxkzfHsLb\nDJ6fl+u7QGa3cRF1G5HvgirNC7ISNFWk4WOkOkmKolEFseISxpHdp194qKHrPb8N\n0YZmIqYSnGhIUDFwV8QElqoISONlbQS7UmQTSRpzTQ8moEb19jvRAHJDAoGAa2GH\n5s3tPtkbAjqtpM4gdCPW1MFZJANMK85h1ISbsv98/A/e4jmULtraCxYKt6QtSq9D\nDuJWukDvxUdm/fNmwqEmN1wkypMgFmL5qncYjuj6SUAlPpUkquXIlhaCQSnj9CIc\nYgcooBpMZvA7tMKgG5jQWZsASQeVZ59PkV4BNEUCgYEAmyI4q2V0dzovxtxiVQ4W\n7pnqUlLDEJ1DZ+lobsW9h8LmvJhUxd5gZhr7Mz5P5R3gNdNYyV8oj8DLOqyV1T6M\nR/80VXZwE2c9Pmzhn7yPlQ+SufJw1nFApSmuGlTABqp5MMgSR5cZAk5Ds5inFSS3\nTqTeWbhFy6GziIynsVdr84w=\n-----END PRIVATE KEY-----\n", #String.replace(System.get_env(FYR_KEY),~r[/\\n/g], '\n'),
# }

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :phos, Phos.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
