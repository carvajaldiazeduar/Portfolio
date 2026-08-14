defmodule TasksList.MixProject do
  use Mix.Project

  def project do
    [
      app: :tasks_list_cli,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: []
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp escript do
    [main_module: TasksList.CLI]
  end
end