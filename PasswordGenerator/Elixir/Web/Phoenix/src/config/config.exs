# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :password_generator,
  ecto_repos: [PasswordGenerator.Repo],
  generators: [timestamp_type: :utc_datetime],
  cache_type: System.get_env("CACHE_TYPE", "local"),
  redis_host: System.get_env("REDIS_HOST", "localhost:6379"),
  cache_ttl: String.to_integer(System.get_env("CACHE_TTL", "300"))

# Configure the endpoint
config :password_generator, PasswordGeneratorWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: PasswordGeneratorWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PasswordGenerator.PubSub,
  live_view: [signing_salt: "mJeiOfyA"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
