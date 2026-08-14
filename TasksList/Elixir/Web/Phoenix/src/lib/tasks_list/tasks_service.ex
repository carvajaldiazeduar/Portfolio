defmodule TasksList.TasksService do
  @moduledoc """
  Service layer for tasks: cache-first reads with DB fallback.
  Writes invalidate the `tasks:all` cache key.
  """

  alias TasksList.{Cache, Repo, Task}
  import Ecto.Query

  def list_all(ttl \\ default_ttl()) do
    case Cache.get("tasks:all") do
      {:ok, tasks} -> tasks
      :error ->
        tasks = Repo.all(from t in Task, order_by: t.id)
        Cache.set("tasks:all", tasks, ttl)
        tasks
    end
  end

  def show(id) do
    case Repo.get(Task, id) do
      nil -> :error
      task -> {:ok, task}
    end
  end

  def create(attrs) do
    changeset = Task.changeset(%Task{}, attrs)

    if changeset.valid? do
      case Repo.insert(changeset) do
        {:ok, task} ->
          invalidate_all()
          {:ok, task}

        {:error, changeset} ->
          {:error, Task.error_map(changeset)}
      end
    else
      {:error, Task.error_map(changeset)}
    end
  end

  def update(id, attrs) do
    case Repo.get(Task, id) do
      nil ->
        {:error, :not_found}

      task ->
        changeset = Task.changeset(task, attrs)

        if changeset.valid? do
          case Repo.update(changeset) do
            {:ok, task} ->
              invalidate_all()
              {:ok, task}

            {:error, changeset} ->
              {:error, Task.error_map(changeset)}
          end
        else
          {:error, Task.error_map(changeset)}
        end
    end
  end

  def delete(id) do
    case Repo.get(Task, id) do
      nil ->
        {:error, :not_found}

      task ->
        Repo.delete(task)
        invalidate_all()
        {:ok, task}
    end
  end

  defp invalidate_all do
    Cache.delete("tasks:all")
  end

  defp default_ttl do
    Application.get_env(:tasks_list, :cache_ttl, 300)
  end
end