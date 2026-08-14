defmodule ChatAI.Test.MockHttp do
  @moduledoc """
  Mock HTTP client for ChatAI tests.

  Tests configure a queue of responses with `set_responses/1`; each `post_json`
  call pops the next one. The last request url+payload are captured for
  assertion tests.
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{responses: [], last_url: nil, last_payload: nil} end,
      name: __MODULE__
    )
  end

  def set_responses(responses) do
    Agent.update(__MODULE__, fn state -> %{state | responses: responses} end)
  end

  def clear do
    Agent.update(__MODULE__, fn _ -> %{responses: [], last_url: nil, last_payload: nil} end)
  end

  def post_json(url, _headers, payload, _timeout) do
    result =
      Agent.get_and_update(__MODULE__, fn state ->
        case state.responses do
          [{:ok, body} | rest] -> {{:ok, body}, %{state | responses: rest}}
          [{:error, msg} | rest] -> {{:error, msg}, %{state | responses: rest}}
          [:hang | rest] -> {:hang, %{state | responses: rest}}
          [] -> {{:ok, Jason.encode!(%{})}, state}
        end
      end)

    case result do
      :hang ->
        Process.sleep(60_000)
        {:error, "timed out"}

      _ ->
        Agent.update(__MODULE__, fn state ->
          %{state | last_url: to_string(url), last_payload: payload}
        end)

        result
    end
  end

  def last_request do
    Agent.get(__MODULE__, fn state -> {state.last_url, state.last_payload} end)
  end
end
