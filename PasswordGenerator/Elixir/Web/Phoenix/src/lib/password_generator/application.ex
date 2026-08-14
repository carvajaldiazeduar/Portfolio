defmodule PasswordGenerator.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
        children =
      [
        PasswordGeneratorWeb.Telemetry,
        PasswordGenerator.Repo,
        {DNSCluster, query: Application.get_env(:password_generator, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: PasswordGenerator.PubSub},
        PasswordGenerator.Cache.LocalCache
      ] ++
        if(Application.get_env(:password_generator, :cache_type, "local") == "redis", do: [
          {PasswordGenerator.Cache.RedisCache,
           host: Application.get_env(:password_generator, :redis_host, "localhost:6379")}
        ], else: []) ++
        [
          # Start to serve requests, typically the last entry
          PasswordGeneratorWeb.Endpoint
        ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PasswordGenerator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PasswordGeneratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
