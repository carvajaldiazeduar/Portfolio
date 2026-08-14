defmodule TasksList.Task do
  @moduledoc """
  Task: title, description and completed state.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :title, :description, :completed, :inserted_at, :updated_at]}

  schema "tasks" do
    field :title, :string
    field :description, :string, default: ""
    field :completed, :boolean, default: false

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :completed], trim: true)
    |> validate_required([:title], message: "is required", trim: true)
  end

  def error_map(changeset) do
    Enum.reduce(changeset.errors, %{}, fn {field, {message, _opts}}, acc ->
      Map.put(acc, field, error_message(field, message))
    end)
  end

  defp error_message(_field, "is required"), do: "Title is required"
end