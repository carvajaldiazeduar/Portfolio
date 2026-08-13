defmodule Chronometer.StopwatchTest do
  use ExUnit.Case, async: false

  setup do
    Chronometer.Stopwatch.reset()
    :ok
  end

  test "starts the stopwatch" do
    assert {:ok, %{state: "running"}} = Chronometer.Stopwatch.start()
  end

  test "pauses and reports elapsed" do
    Chronometer.Stopwatch.start()
    assert {:ok, %{state: "paused", elapsed: elapsed}} = Chronometer.Stopwatch.pause()
    assert is_number(elapsed)
  end

  test "resumes after pause" do
    Chronometer.Stopwatch.start()
    Chronometer.Stopwatch.pause()
    assert {:ok, %{state: "running"}} = Chronometer.Stopwatch.resume()
  end

  test "reset zeroes elapsed" do
    Chronometer.Stopwatch.start()
    Chronometer.Stopwatch.pause()
    assert {:ok, %{elapsed: 0}} = Chronometer.Stopwatch.reset()
  end

  test "status reports paused by default" do
    assert {:ok, %{state: "paused", elapsed: 0.0}} = Chronometer.Stopwatch.status()
  end

  test "status reports running while running" do
    Chronometer.Stopwatch.start()
    assert {:ok, %{state: "running"}} = Chronometer.Stopwatch.status()
  end
end
