defmodule Inboxes.Repo do
  use Ecto.Repo,
    otp_app: :inboxes,
    adapter: Inboxes.RepoAdapter.resolve()
end