defmodule Phos.MixProject do
  use Mix.Project

  def project do
    [
      app: :phos,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        warnings_as_errors: true
      ],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Phos.Application, []},
      extra_applications: [:lager, :logger, :runtime_tools, :inets]
      # :wx, :observer
      # extra_applications: [:logger, :runtime_tools, :wx]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.7", override: true},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.5", override: true},
      {:floki, ">= 0.34.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:dotenv_parser, "~> 2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.11"},
      {:gen_smtp, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.5"},
      {:joken, "~> 2.5"},
      {:h3, github: "helium/erlang-h3"},
      {:libcluster, "~> 3.3"},
      {:heroicons, "~> 0.5.2"},
      # support aws s3
      {:ex_aws, "~> 2.3"},
      {:ex_aws_s3, "~> 2.3"},
      {:sweet_xml, "~> 0.7"},
      {:httpoison, "~> 1.8"},
      {:mogrify, "~> 0.9.1"},

      # oauth strategy
      {:argon2_elixir, "~> 3.0"},
      {:assent, "~> 0.2.0"},
      {:certifi, "~> 2.4"},
      {:ssl_verify_fun, "~> 1.1"},
      {:ecto_psql_extras, "~> 0.7.10"},
      {:mint, "~> 1.0"},
      {:castore, "~> 0.1.3"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:timex, "~> 3.7"},
      {:earmark, "~>1.4.36"},
      {:html_sanitize_ex, "~> 1.4"},
      # {:prom_ex, "~> 1.7.1"},
      {:prom_ex, github: "KosmonautX/prom_ex"},
      {:fsmx, "~> 0.4"},
      {:nebulex, "~> 2.5.2"},
      {:shards, "~> 1.0"},
      {:decorator, "~> 1.4"},
      {:retry, "~> 0.17"},
      {:uuid, "~> 1.1" },
      # comments
      {:ecto_ltree, "~> 0.3.0"},
      {:sparrow, sparrow_dep()},
      {:bumblebee, "~> 0.3.1"},
      {:exla, "~> 0.6.0"},
      #debugging
      {:rexbug, "~> 1.0"},
      {:gen_stage, "~> 1.2"},
      {:poison, "4.0.1", override: true},
      {:phoenix_view, "~> 2.0"}, # for error warning removal
      {:finch, "~> 0.15.0"},
      {:req, "~> 0.4.0"},
      {:pgvector, "~> 0.2.0"},
      # { :uuid, "~> 1.1" },
      # {:phx_live_storybook, "~> 0.4.0", runtime: Mix.env() == :dev}
      {:ex_gram, "~> 0.40.0"},
      {:tesla, "~> 1.2"},
      {:phx_live_storybook, github: "phenixdigital/phx_live_storybook", tag: "992062c", runtime: Mix.env() == :dev},
      # To Support Legacy Logger Backend since v1.15
      {:logger_backends, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp sparrow_dep() do
    if path = System.get_env("SPARROW_PATH") do
      [path: path]
    else
      [github: "satrionugroho/sparrow", tag: "v1.0.3"]
    end
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "tailwind default --minify",
        "tailwind admin --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
