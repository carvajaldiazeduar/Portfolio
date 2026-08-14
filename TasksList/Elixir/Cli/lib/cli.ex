defmodule TasksList.CLI do
  @moduledoc """
  Interactive task list CLI (escript entry point).
  """

  alias TasksList

  def main(_args) do
    loop([])
  end

  defp loop(tasks) do
    IO.puts("\n=== Tasks List ===")
    IO.puts("1. Add Task")
    IO.puts("2. List Tasks")
    IO.puts("3. Complete Task")
    IO.puts("4. Delete Task")
    IO.puts("5. Exit")

    case read_int("Choice") do
      1 -> loop(add(tasks))
      2 -> loop(list(tasks))
      3 -> loop(complete(tasks))
      4 -> loop(delete(tasks))
      5 -> IO.puts("Goodbye!")
      _ ->
        IO.puts("Invalid choice")
        loop(tasks)
    end
  end

  defp add(tasks) do
    title = read_line("Title")
    description = read_line("Description")
    {:ok, task} = TasksList.add_task(tasks, title, description)
    IO.puts("Task added (id=#{task.id})")
    [task | tasks]
  end

  defp list(tasks) do
    case TasksList.list_tasks(tasks) do
      [] ->
        IO.puts("No tasks found.")

      list ->
        Enum.each(list, fn t ->
          status = if t.completed, do: "[x]", else: "[ ]"
          IO.puts("#{status} #{t.id}. #{t.title} - #{t.created_at}")
        end)
    end

    tasks
  end

  defp complete(tasks) do
    id = read_int("Task ID")

    case TasksList.complete_task(tasks, id) do
      {:ok, _} ->
        IO.puts("Task completed.")
        Enum.map(tasks, fn t -> if t.id == id, do: %{t | completed: true}, else: t end)

      {:error, :not_found} ->
        IO.puts("Task not found.")
        tasks
    end
  end

  defp delete(tasks) do
    id = read_int("Task ID")

    case TasksList.delete_task(tasks, id) do
      {:ok, _} ->
        IO.puts("Task deleted.")
        Enum.reject(tasks, &(&1.id == id))

      {:error, :not_found} ->
        IO.puts("Task not found.")
        tasks
    end
  end

  defp read_line(prompt) do
    IO.gets("#{prompt}: ") |> String.trim()
  end

  defp read_int(prompt) do
    case Integer.parse(IO.gets("#{prompt}: ")) do
      {n, _} -> n
      :error -> -1
    end
  end
end