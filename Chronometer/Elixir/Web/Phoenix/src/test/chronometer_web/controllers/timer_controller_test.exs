defmodule ChronometerWeb.TimerControllerTest do
  use ChronometerWeb.ConnCase, async: false

  setup do
    Chronometer.Stopwatch.reset()
    :ok
  end

  test "GET /status returns paused by default", %{conn: conn} do
    conn = get(conn, "/status")
    assert json_response(conn, 200) == %{"state" => "paused", "elapsed" => 0.0}
  end

  test "POST /start returns running", %{conn: conn} do
    conn = post(conn, "/start")
    assert json_response(conn, 200) == %{"state" => "running"}
  end

  test "POST /pause returns paused with elapsed", %{conn: conn} do
    post(conn, "/start")
    conn = post(conn, "/pause")
    assert %{"state" => "paused"} = json_response(conn, 200)
  end

  test "POST /resume returns running", %{conn: conn} do
    post(conn, "/start")
    post(conn, "/pause")
    conn = post(conn, "/resume")
    assert json_response(conn, 200) == %{"state" => "running"}
  end

  test "POST /reset returns zeroed elapsed", %{conn: conn} do
    post(conn, "/start")
    conn = post(conn, "/reset")
    assert json_response(conn, 200) == %{"elapsed" => 0}
  end

  test "GET /swagger redirects", %{conn: conn} do
    conn = get(conn, "/swagger")
    assert redirected_to(conn, 302) == "/swagger.html"
  end
end
