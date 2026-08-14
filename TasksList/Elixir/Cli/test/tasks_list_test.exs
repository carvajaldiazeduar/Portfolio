defmodule TasksListTest do
  use ExUnit.Case, async: true

  alias TasksList

  test "add_task creates an incomplete task" do
    assert {:ok, t} = TasksList.add_task([], "Buy milk", "2 liters")
    assert t.id == 1
    assert t.title == "Buy milk"
    assert t.description == "2 liters"
    assert t.completed == false
    assert t.created_at != nil
  end

  test "add_task increments ids" do
    {:ok, t1} = TasksList.add_task([], "Buy milk", "")
    {:ok, t2} = TasksList.add_task([t1], "Write docs", "")
    assert t1.id == 1
    assert t2.id == 2
  end

  test "list_tasks returns all" do
    {:ok, t1} = TasksList.add_task([], "Buy milk", "")
    {:ok, t2} = TasksList.add_task([t1], "Write docs", "")
    assert TasksList.list_tasks([t1, t2]) == [t1, t2]
  end

  test "complete_task marks as completed" do
    {:ok, t} = TasksList.add_task([], "Buy milk", "")
    assert {:ok, done} = TasksList.complete_task([t], 1)
    assert done.completed == true
  end

  test "complete_task missing returns not_found" do
    assert TasksList.complete_task([], 99) == {:error, :not_found}
  end

  test "delete_task removes by id" do
    {:ok, t} = TasksList.add_task([], "Buy milk", "")
    assert {:ok, ^t} = TasksList.delete_task([t], 1)
  end

  test "delete_task missing returns not_found" do
    assert TasksList.delete_task([], 99) == {:error, :not_found}
  end
end