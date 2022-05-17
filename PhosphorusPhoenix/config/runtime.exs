import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Start the phoenix server if environment is set and running in a release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :phos, PhosWeb.Endpoint, server: true
end

unless config_env() == :prod do
  #dotenv Parsing .env file
  DotenvParser.load_file('../.env')

  # Joken Signer Config
  config :joken, menshenSB: [
    signer_alg: "HS256",
    key_octet: "BALA"
  ]

  # FCM

  config :phos, Phos.Fyr.Message,
  adapter: Pigeon.FCM,
  project_id: System.get_env("FYR_PROJ"),
  service_account_json: "{\n  \"type\": \"service_account\",\n  \"project_id\": \"#{System.get_env("FYR_PROJ")}\",\n  \"private_key\": \"#{System.get_env("FYR_KEY") |> String.replace("\n", "\\n")}\",\n  \"client_email\": \"#{System.get_env("FYR_EMAIL")}\"\n}\n"

end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []


  app_name =
    System.get_env("FLY_APP_NAME") ||
    raise "FLY_APP_NAME not available"

  config :libcluster,
    debug: true,
    topologies: [
      fly6pn: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]


  # FCM Prod
  config :phos, Phos.Fyr.Message,
    adapter: Pigeon.FCM,
    project_id: System.get_env("FYR_PROJ"),
    service_account_json: "{\n  \"type\": \"service_account\",\n  \"project_id\": \"#{System.get_env("FYR_PROJ")}\",\n  \"private_key\": \"#{System.get_env("FYR_KEY") |> String.replace("\n", "\\n")}\",\n  \"client_email\": \"#{System.get_env("FYR_EMAIL")}\"\n}\n"

  config :phos, Phos.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE")

  host = System.get_env("PHX_HOST") || "phos.scrb.ac"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :phos, PhosWeb.Endpoint,
    url: [host: host, port: 443],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :joken, menshenSB: [
    signer_alg: "HS256",
    key_octet: System.get_env("SECRET_TUNNEL")
  ]

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :phos, PhosWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :phos, Phos.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end