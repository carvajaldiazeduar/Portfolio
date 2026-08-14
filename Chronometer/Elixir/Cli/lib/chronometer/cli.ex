defmodule Chronometer.CLI do
  @moduledoc """
  Interactive CLI for Chronometer built as a mix escript.
  """

  def main(_args) do
    loop(Chronometer.new())
  end

  defp loop(state) do
    draw(state)

    case IO.gets("Control [S]tart [P]ause [R]eset [Q]uit: ") |> String.trim() |> String.downcase() do
      "s" -> loop(Chronometer.start(state))
      "p" -> loop(Chronometer.stop(state))
      "r" -> loop(Chronometer.reset(state))
      "q" -> System.halt(0)
      _ -> loop(state)
    end
  end

  defp draw(state) do
    IO.ANSI.clear() |> IO.write()
    IO.puts("=== Chronometer ===")
    IO.puts("")
    IO.puts("  Status: #{if state.running, do: "Running", else: "Stopped"}")
    IO.puts("  Time:   #{format_time(Chronometer.elapsed(state))}")
    IO.puts("")
  end

  def format_time(seconds) do
    total_ms = round(seconds * 1000)
    hours = div(total_ms, 3_600_000)
    minutes = rem(total_ms, 3_600_000) |> div(60_000)
    secs = rem(total_ms, 60_000) |> div(1000)
    millis = rem(total_ms, 1000)
    :io_lib.format("~2..0B:~2..0B:~2..0B.~3..0B", [hours, minutes, secs, millis]) |> to_string()
  end
end
