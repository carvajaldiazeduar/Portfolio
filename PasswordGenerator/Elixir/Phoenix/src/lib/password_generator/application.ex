defmodule PasswordGenerator.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PasswordGenerator.Repo,
      {Phoenix.PubSub, name: PasswordGenerator.PubSub},
      PasswordGenerator.Cache,
      PasswordGeneratorWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PasswordGenerator.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PasswordGeneratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
