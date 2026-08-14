defmodule Chronometer.Stopwatch do
  use GenServer

  defstruct running: false, started_at: nil, elapsed: 0.0

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def start, do: GenServer.call(__MODULE__, :start)
  def pause, do: GenServer.call(__MODULE__, :pause)
  def resume, do: GenServer.call(__MODULE__, :resume)
  def reset, do: GenServer.call(__MODULE__, :reset)
  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:start, _from, %__MODULE__{running: false} = state) do
    {:reply, {:ok, %{state: "running"}}, %{state | running: true, started_at: monotonic()}}
  end

  def handle_call(:start, _from, %__MODULE__{} = state) do
    {:reply, {:ok, %{state: "running"}}, state}
  end

  @impl true
  def handle_call(:pause, _from, %__MODULE__{running: true} = state) do
    state = %{state | elapsed: current_elapsed(state), running: false, started_at: nil}
    {:reply, {:ok, %{state: "paused", elapsed: round3(state.elapsed)}}, state}
  end

  def handle_call(:pause, _from, state) do
    {:reply, {:ok, %{state: "paused", elapsed: round3(state.elapsed)}}, state}
  end

  @impl true
  def handle_call(:resume, _from, %__MODULE__{running: false} = state) do
    {:reply, {:ok, %{state: "running"}}, %{state | running: true, started_at: monotonic()}}
  end

  def handle_call(:resume, _from, state) do
    {:reply, {:ok, %{state: "running"}}, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, {:ok, %{elapsed: 0}}, %__MODULE__{}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, {:ok, status_payload(state)}, state}
  end

  defp status_payload(%__MODULE__{running: true} = state) do
    %{state: "running", elapsed: round3(current_elapsed(state))}
  end

  defp status_payload(%__MODULE__{} = state) do
    %{state: "paused", elapsed: round3(state.elapsed)}
  end

  defp current_elapsed(%__MODULE__{running: true, started_at: started_at} = state) do
    state.elapsed + (monotonic() - started_at) / 1000
  end

  defp current_elapsed(%__MODULE__{} = state), do: state.elapsed

  defp monotonic, do: System.monotonic_time(:millisecond)

  defp round3(value), do: Float.round(value, 3)
end
