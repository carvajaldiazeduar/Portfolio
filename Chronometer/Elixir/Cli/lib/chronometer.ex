defmodule Chronometer do
  @moduledoc """
  Stopwatch state machine used by the CLI. The Web keeps its own
  supervised GenServer (see the Phoenix app), this module is the
  pure simulation core for the CLI.
  """

  defstruct running: false, started_at: nil, elapsed: 0.0, laps: []

  def new, do: %__MODULE__{}

  def start(%__MODULE__{} = state) do
    if state.running do
      state
    else
      %{state | running: true, started_at: monotonic()}
    end
  end

  def stop(%__MODULE__{} = state) do
    if state.running do
      %{state | elapsed: current_elapsed(state), running: false, started_at: nil}
    else
      state
    end
  end

  def reset(_state), do: new()

  def lap(%__MODULE__{} = state) do
    if state.running do
      %{state | laps: state.laps ++ [current_elapsed(state)]}
    else
      state
    end
  end

  def elapsed(%__MODULE__{} = state), do: current_elapsed(state)

  def current_elapsed(%__MODULE__{running: true, started_at: started_at} = state) do
    state.elapsed + (monotonic() - started_at) / 1000
  end

  def current_elapsed(%__MODULE__{} = state), do: state.elapsed

  def monotonic, do: System.monotonic_time(:millisecond)
end
