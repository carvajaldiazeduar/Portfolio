defmodule TasksListWeb.TaskControllerTest do
  use TasksListWeb.ConnCase, async: true

  alias TasksList.TasksService

  setup do
    TasksList.Cache.delete("tasks:all")
    :ok
  end

  test "GET /api/tasks lists tasks", %{conn: conn} do
    {:ok, _} = TasksService.create(%{title: "Buy milk"})
    conn = get(conn, "/api/tasks")
    assert [task] = json_response(conn, 200)
    assert task["title"] == "Buy milk"
    assert task["completed"] == false
  end

  test "POST /api/tasks creates", %{conn: conn} do
    conn = post(conn, "/api/tasks", %{title: "Buy milk", description: "2 liters"})
    assert %{"id" => id, "title" => "Buy milk"} = json_response(conn, 201)
    assert is_integer(id)
  end

  test "POST /api/tasks validates", %{conn: conn} do
    conn = post(conn, "/api/tasks", %{title: ""})
    assert json_response(conn, 400) == %{"errors" => %{"title" => "Title is required"}}
  end

  test "GET /api/tasks/:id shows one", %{conn: conn} do
    {:ok, task} = TasksService.create(%{title: "Buy milk"})
    id = task.id
    conn = get(conn, "/api/tasks/#{id}")
    assert %{"id" => ^id} = json_response(conn, 200)
  end

  test "GET /api/tasks/:id missing returns 404", %{conn: conn} do
    conn = get(conn, "/api/tasks/999999")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "PUT /api/tasks/:id updates title", %{conn: conn} do
    {:ok, task} = TasksService.create(%{title: "Buy milk"})
    conn = put(conn, "/api/tasks/#{task.id}", %{title: "Buy oat milk"})
    assert %{"title" => "Buy oat milk"} = json_response(conn, 200)
  end

  test "PUT /api/tasks/:id updates completed", %{conn: conn} do
    {:ok, task} = TasksService.create(%{title: "Buy milk"})
    conn = put(conn, "/api/tasks/#{task.id}", %{completed: true})
    assert %{"completed" => true} = json_response(conn, 200)
  end

  test "PUT /api/tasks/:id missing returns 404", %{conn: conn} do
    conn = put(conn, "/api/tasks/999999", %{completed: true})
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "DELETE /api/tasks/:id deletes", %{conn: conn} do
    {:ok, task} = TasksService.create(%{title: "Buy milk"})
    conn = delete(conn, "/api/tasks/#{task.id}")
    assert json_response(conn, 200) == %{"result" => "deleted"}
  end

  test "DELETE /api/tasks/:id missing returns 404", %{conn: conn} do
    conn = delete(conn, "/api/tasks/999999")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "GET /swagger redirects", %{conn: conn} do
    conn = get(conn, "/swagger")
    assert redirected_to(conn, 302) == "/swagger.html"
  end
end