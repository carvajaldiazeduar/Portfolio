defmodule SemanticSearch.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        SemanticSearchWeb.Telemetry,
        {DNSCluster, query: Application.get_env(:semantic_search, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: SemanticSearch.PubSub},
        SemanticSearch.Cache.LocalCache,
        SemanticSearch.VectorStore.InMemoryVectorStore
      ] ++
        if(Application.get_env(:semantic_search, :cache_type, "local") == "redis",
          do: [
            {SemanticSearch.Cache.RedisCache,
             host: Application.get_env(:semantic_search, :redis_host, "localhost:6379")}
          ],
          else: []
        ) ++
        [
          SemanticSearchWeb.Endpoint
        ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SemanticSearch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SemanticSearchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
