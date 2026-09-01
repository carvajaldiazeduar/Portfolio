defmodule ChatAI.ChatRequest do
  @moduledoc """
  Incoming chat request: messages + optional provider/model/temperature/max_tokens.
  """
  defstruct [:messages, :provider, :model, :temperature, :max_tokens]

  @type t :: %__MODULE__{
          messages: [ChatAI.Message.t()],
          provider: String.t() | nil,
          model: String.t() | nil,
          temperature: float | nil,
          max_tokens: integer | nil
        }

  @spec from_map(map | nil) :: t | nil
  def from_map(%{} = params) do
    messages =
      case params["messages"] do
        list when is_list(list) ->
          Enum.map(list, &ChatAI.Message.from_map/1) |> Enum.reject(&is_nil/1)

        _ ->
          []
      end

    %__MODULE__{
      messages: messages,
      provider: params["provider"],
      model: params["model"],
      temperature: parse_number(params["temperature"]),
      max_tokens: parse_int(params["max_tokens"])
    }
  end

  def from_map(_), do: nil

  defp parse_number(n) when is_number(n), do: n * 1.0

  defp parse_number(s) when is_binary(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> nil
    end
  end

  defp parse_number(_), do: nil

  defp parse_int(n) when is_integer(n), do: n

  defp parse_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp parse_int(_), do: nil
end
