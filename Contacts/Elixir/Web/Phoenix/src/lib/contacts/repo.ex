defmodule Contacts.Repo do
  use Ecto.Repo,
    otp_app: :contacts,
    adapter: Contacts.RepoAdapter.resolve()
end