defmodule TasksList.Repo do
  use Ecto.Repo,
    otp_app: :tasks_list,
    adapter: TasksList.RepoAdapter.resolve()
end