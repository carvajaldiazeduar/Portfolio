defmodule TasksList.TaskTest do
  use TasksList.DataCase, async: true

  alias TasksList.Task

  test "valid task is saved" do
    changeset = Task.changeset(%Task{}, %{title: "Buy milk"})
    assert changeset.valid?
  end

  test "title is required" do
    changeset = Task.changeset(%Task{}, %{title: ""})
    refute changeset.valid?
    assert Task.error_map(changeset) == %{title: "Title is required"}
  end

  test "whitespace treated as missing" do
    changeset = Task.changeset(%Task{}, %{title: "   "})
    refute changeset.valid?
    assert Task.error_map(changeset) == %{title: "Title is required"}
  end

  test "completed defaults to false" do
    {:ok, task} =
      TasksList.Repo.insert(Task.changeset(%Task{}, %{title: "Buy milk"}))

    assert task.completed == false
    assert task.description == ""
  end
end