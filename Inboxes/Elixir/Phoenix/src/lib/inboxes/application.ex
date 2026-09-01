defmodule Inboxes.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Inboxes.Repo,
      {Phoenix.PubSub, name: Inboxes.PubSub},
      Inboxes.Cache,
      InboxesWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Inboxes.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    InboxesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
