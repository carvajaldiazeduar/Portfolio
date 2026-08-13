defmodule ChronometerWeb.TimerController do
  use ChronometerWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:chronometer, "priv/static/index.html"))
  end

  def status(conn, _params) do
    {:ok, payload} = Chronometer.Stopwatch.status()
    json(conn, payload)
  end

  def start(conn, _params) do
    {:ok, payload} = Chronometer.Stopwatch.start()
    json(conn, payload)
  end

  def pause(conn, _params) do
    {:ok, payload} = Chronometer.Stopwatch.pause()
    json(conn, payload)
  end

  def resume(conn, _params) do
    {:ok, payload} = Chronometer.Stopwatch.resume()
    json(conn, payload)
  end

  def reset(conn, _params) do
    {:ok, payload} = Chronometer.Stopwatch.reset()
    json(conn, payload)
  end

  def swagger(conn, _params) do
    redirect(conn, to: "/swagger.html")
  end
end
