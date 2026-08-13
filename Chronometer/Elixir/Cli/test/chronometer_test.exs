defmodule ChronometerTest do
  use ExUnit.Case, async: true

  alias Chronometer, as: S

  test "new stopwatch starts stopped at zero" do
    state = S.new()
    assert state.running == false
    assert S.elapsed(state) == 0.0
    assert state.laps == []
  end

  test "start sets running state" do
    state = S.new() |> S.start()
    assert state.running == true
  end

  test "starting twice is idempotent" do
    state = S.new() |> S.start() |> S.start()
    assert state.running == true
  end

  test "stop freezes elapsed time" do
    state = S.new() |> S.start() |> S.stop()
    assert state.running == false
    assert is_number(state.elapsed)
  end

  test "reset returns a fresh stopwatch" do
    state = S.new() |> S.start() |> S.stop() |> S.reset()
    assert state.running == false
    assert S.elapsed(state) == 0.0
    assert state.laps == []
  end

  test "lap only records while running" do
    state = S.new() |> S.lap()
    assert state.laps == []

    state = S.new() |> S.start() |> S.lap()
    assert length(state.laps) == 1
  end

  test "format_time produces HH:MM:SS.mmm" do
    assert Chronometer.CLI.format_time(0.0) == "00:00:00.000"
    assert Chronometer.CLI.format_time(3661.5) == "01:01:01.500"
  end
end
