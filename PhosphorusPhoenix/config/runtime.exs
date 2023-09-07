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

## Shared Configs
##
config :phos, Phos.Notification, worker: 1

unless config_env() == :prod do
  #dotenv Parsing .env file
  DotenvParser.load_file('../.env')

  # # FCM
  # config :phos, Phos.Fyr.Message,
  # adapter: Pigeon.FCM,
  # project_id: System.get_env("FYR_PROJ"),
  # service_account_json: "{\n  \"type\": \"service_account\",\n  \"project_id\": \"#{System.get_env("FYR_PROJ")}\",\n  \"private_key\": \"#{System.get_env("FYR_KEY", "") |> String.replace("\n", "\\n")}\",\n  \"client_email\": \"#{System.get_env("FYR_EMAIL")}\"\n}\n"

  # Sparrow
  sparrow_path = :code.priv_dir(:phos) |> to_string() |> Kernel.<>("/data/sparrow_config.json")
    File.touch(sparrow_path)
    File.write!(sparrow_path, "{\n  \"type\": \"service_account\",\n  \"project_id\": \"#{System.get_env("FYR_PROJ")}\",\n  \"private_key\": \"#{System.get_env("FYR_KEY", "") |> String.replace("\n", "\\n")}\",\n  \"client_email\": \"#{System.get_env("FYR_EMAIL")}\"\n}\n")

  config :sparrow,
    pool_enabled: true,
    fcm: [
      [
        path_to_json: sparrow_path,
        ping_interval: 3000,
        worker_num: 50
      ]
    ]


  # AWS
  config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: "ap-southeast-1"

  # Joken JWT Settings
  config :joken, menshenSB: [
    signer_alg: "HS256",
    key_octet: System.get_env("SECRET_TUNNEL")
  ]


  # Notion Importing / Exporting
  config :phos, Phos.External.Notion,
  token: System.get_env("NOTION_TOKEN"),
  database: System.get_env("NOTION_DATABASE"),
  version: System.get_env("NOTION_VERSION")

  #Precached town hexagons
  config :phos, Phos.External.Sector,
  url: System.get_env("SECTOR_URL")

  # Prometheus
  config :phos, Phos.PromEx,
  disabled: true,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: [
      host: System.get_env("GRAFANA_HOST") || raise("GRAFANA_HOST is required"),
      auth_token: System.get_env("GRAFANA_TOKEN") || raise("GRAFANA_TOKEN is required"),
      upload_dashboards_on_start: true,
      folder_name: (System.get_env("FLY_APP_NAME") || "phos") <> "Dashboard",
      annotate_app_lifecycle: true
    ],
  metrics_server: [
      port: 3927,
      path: "/metrics", # This is an optional setting and will default to `"/metrics"`
      protocol: :http, # This is an optional setting and will default to `:http`
      pool_size: 9, # This is an optional setting and will default to `5`
      cowboy_opts: [], # This is an optional setting and will default to `[]`
      auth_strategy: :none # This is an optional and will default to `:none`
    ]


  # Admin Console
  config :phos, Phos.Admin,
  password: System.get_env("ADMIN_TUNNEL"),
  algorithm: :sha256

  # Telegram Bot
  config :ex_gram,
  token: System.get_env("TELEGRAM_BOT_ID"),
  json_engine: Jason

  config :ex_gram, :webhook,
# allowed_updates: ["message", "poll"],       # array of strings
# certificate: "priv/cert/selfsigned.pem",    # string (file path)
  drop_pending_updates: true,                # boolean
# ip_address: "1.1.1.1",                      # string
# max_connections: 50,                        # integer
# secret_token: "some_super_secret_key",      # string
  url: System.get_env("TELEGRAM_REDIRECT_HOST") #

end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL")

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  # # Sparrow
  sparrow_path = :code.priv_dir(:phos) |> to_string() |> Kernel.<>("/data/sparrow_config.json")
    File.touch(sparrow_path)
    File.write!(sparrow_path, "{\n  \"type\": \"service_account\",\n  \"project_id\": \"#{System.get_env("FYR_PROJ")}\",\n  \"private_key\": \"#{System.get_env("FYR_KEY", "") |> String.replace("\n", "\\n")}\",\n  \"client_email\": \"#{System.get_env("FYR_EMAIL")}\"\n}\n")

  config :sparrow,
    pool_enabled: true,
    fcm: [
      [
        path_to_json: sparrow_path,
        ping_interval: 3000,
        worker_num: 50
      ]
    ]

  # AWS
  config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: "ap-southeast-1"



  app_name =
    System.get_env("FLY_APP_NAME")

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
  # config :phos, Phos.Fyr.Message,
  #   adapter: Pigeon.FCM,
  #   project_id: System.get_env("FYR_PROJ"),
  #   service_account_json: "{\n  \"type\": \"service_account\",\n  \"project_id\": \"#{System.get_env("FYR_PROJ")}\",\n  \"private_key\": \"#{System.get_env("FYR_KEY", "") |> String.replace("\n", "\\n")}\",\n  \"client_email\": \"#{System.get_env("FYR_EMAIL")}\"\n}\n"

  config :phos, Phos.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "88"),
    socket_options: maybe_ipv6,
    types: Phos.PostgresTypes

  # Joken JWT Settings
  config :joken, menshenSB: [
    signer_alg: "HS256",
    key_octet: System.get_env("SECRET_TUNNEL")
  ]


  # Notion Importing / Exporting
  config :phos, Phos.External.Notion,
  token: System.get_env("NOTION_TOKEN"),
  database: System.get_env("NOTION_DATABASE"),
  version: System.get_env("NOTION_VERSION")

  #Precached town hexagons
  config :phos, Phos.External.Sector,
  url: System.get_env("SECTOR_URL")

  # Prometheus
  config :phos, Phos.PromEx,
    disabled: false,
    manual_metrics_start_delay: :no_delay,
    drop_metrics_groups: [],
    grafana: [
      host: System.get_env("GRAFANA_HOST"),
      auth_token: System.get_env("GRAFANA_TOKEN"),
      upload_dashboards_on_start: true,
      folder_name: System.get_env("FLY_APP_NAME") <> "Dashboard",
      annotate_app_lifecycle: true
    ],
    metrics_server: [
      port: 3927,
      path: "/metrics", # This is an optional setting and will default to `"/metrics"`
      protocol: :http, # This is an optional setting and will default to `:http`
      pool_size: 9, # This is an optional setting and will default to `5`
      cowboy_opts: [], # This is an optional setting and will default to `[]`
      auth_strategy: :none # This is an optional and will default to `:none`
    ]

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE")

  host = System.get_env("PHX_HOST") || "web.scratchbac.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :phos, PhosWeb.Endpoint,
    url: [host: host, scheme: "https", port: 443],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    check_origin: ["https://nyx.scrb.ac", "https://phos.scrb.ac", "https://web.scratchbac.com"],
    secret_key_base: secret_key_base

  config :phos, Phos.Admin,
  password: System.get_env("ADMIN_TUNNEL"),
  algorithm: :sha256

  # Telegram Bot
  config :ex_gram,
  token: System.get_env("TELEGRAM_BOT_ID"),
  json_engine: Jason

  config :ex_gram, :webhook,
  drop_pending_updates: true,                # boolean
  url: System.get_env("TELEGRAM_REDIRECT_HOST")
# certificate: "priv/cert/selfsigned.pem",    # string (file path)

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
  config :phos, Phos.Mailer,
  adapter: Swoosh.Adapters.AmazonSES,
  region: "ap-southeast-1",
  access_key: System.get_env("SES_ACCESS_KEY_ID"),
  secret: System.get_env("SES_SECRET_ACCESS_KEY")
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
