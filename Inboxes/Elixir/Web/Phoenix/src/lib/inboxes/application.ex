defmodule Inboxes.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
        children =
      [
        InboxesWeb.Telemetry,
        Inboxes.Repo,
        {DNSCluster, query: Application.get_env(:inboxes, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Inboxes.PubSub},
        Inboxes.Cache.LocalCache
      ] ++
        if(Application.get_env(:inboxes, :cache_type, "local") == "redis", do: [
          {Inboxes.Cache.RedisCache,
           host: Application.get_env(:inboxes, :redis_host, "localhost:6379")}
        ], else: []) ++
        [
          # Start to serve requests, typically the last entry
          InboxesWeb.Endpoint
        ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Inboxes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InboxesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
