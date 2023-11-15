defmodule Phos.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      # Start the Ecto repository
      Phos.Repo,
      # Start the Telemetry supervisor
      PhosWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Phos.PubSub},
      # Start the Endpoint (http/https)
      PhosWeb.Endpoint,
      Phos.PromEx,
      Phos.Cache,
      {Cluster.Supervisor, [topologies, [name: Phos.ClusterSupervisor]]},
      PhosWeb.Presence,
      {PhosWeb.Watcher, [name: PhosWeb.Watcher, pubsub_server: Phos.PubSub, pool_size: :erlang.system_info(:schedulers_online)]},
      Phos.Notification,
      Phos.PlatformNotification,
      # Phos.Models.TokenClassification
      Phos.Oracle,
      #restart: :temporary supervisor strategy?
      # Start a worker by calling: Phos.Worker.start_link(arg)
      # {Phos.Worker, arg}
      ExGram, # This will setup the Registry.ExGram
      Phos.TeleBot,
      {Task.Supervisor, name: Phos.TaskSupervisor},
      # Finch API client for AWS SES
      {Finch, name: Swoosh.Finch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Phos.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhosWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
