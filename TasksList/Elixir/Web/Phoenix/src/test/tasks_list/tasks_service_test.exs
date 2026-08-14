defmodule TasksList.TasksServiceTest do
  use TasksList.DataCase, async: true

  alias TasksList.{Repo, Task, TasksService}

  setup do
    TasksList.Cache.delete("tasks:all")
    :ok
  end

  test "creates a task" do
    assert {:ok, task} = TasksService.create(%{title: "Buy milk"})
    assert task.title == "Buy milk"
  end

  test "create validates title" do
    assert {:error, %{title: "Title is required"}} = TasksService.create(%{title: ""})
  end

  test "lists all tasks" do
    {:ok, _} = TasksService.create(%{title: "Buy milk"})
    {:ok, _} = TasksService.create(%{title: "Write docs"})
    assert length(TasksService.list_all()) == 2
  end

  test "list is cached" do
    {:ok, _task} = TasksService.create(%{title: "Buy milk"})
    assert [_] = TasksService.list_all()
    assert {:ok, cached} = TasksList.Cache.get("tasks:all")
    assert is_list(cached)
    assert length(cached) == 1
  end

  test "shows one task" do
    {:ok, task} = TasksService.create(%{title: "Buy milk"})
    assert {:ok, found} = TasksService.show(task.id)
    assert found.title == "Buy milk"
  end

  test "show missing returns error" do
    assert TasksService.show(999_999) == :error
  end

  test "updates a task" do
    {:ok, task} = TasksService.create(%{title: "Buy milk"})
    assert {:ok, updated} = TasksService.update(task.id, %{completed: true})
    assert updated.completed == true
  end

  test "update missing returns not found" do
    assert TasksService.update(999_999, %{completed: true}) == {:error, :not_found}
  end

  test "deletes a task" do
    {:ok, task} = TasksService.create(%{title: "Buy milk"})
    assert {:ok, _} = TasksService.delete(task.id)
    assert Repo.get(Task, task.id) == nil
  end

  test "delete missing returns not found" do
    assert TasksService.delete(999_999) == {:error, :not_found}
  end
end