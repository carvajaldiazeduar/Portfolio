defmodule TasksList do
  @moduledoc """
  Task list core: an in-memory task store with the canonical CLI behaviour.

  Mirrors the Ruby CLI:

  - `add_task(tasks, title, description)` -> task struct with id/title/description/completed/created_at
  - `list_tasks(tasks)` -> all tasks
  - `complete_task(tasks, id)` -> marks as completed
  - `delete_task(tasks, id)` -> removes by id

  Return style: `{:ok, task}` / `{:error, :not_found}`.
  """

  defstruct [:id, :title, :description, :completed, :created_at]

  @type t :: %__MODULE__{
          id: pos_integer,
          title: String.t(),
          description: String.t(),
          completed: boolean,
          created_at: String.t()
        }

  @spec add_task([t()], String.t(), String.t()) :: {:ok, t()}
  def add_task(tasks, title, description) do
    id = (Enum.map(tasks, & &1.id) |> Enum.max(fn -> 0 end)) + 1

    task = %__MODULE__{
      id: id,
      title: title,
      description: description,
      completed: false,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {:ok, task}
  end

  @spec list_tasks([t()]) :: [t()]
  def list_tasks(tasks), do: tasks

  @spec complete_task([t()], pos_integer) :: {:ok, t()} | {:error, :not_found}
  def complete_task(tasks, id) do
    case Enum.find(tasks, &(&1.id == id)) do
      nil -> {:error, :not_found}
      task -> {:ok, %{task | completed: true}}
    end
  end

  @spec delete_task([t()], pos_integer) :: {:ok, t()} | {:error, :not_found}
  def delete_task(tasks, id) do
    case Enum.find(tasks, &(&1.id == id)) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end
end