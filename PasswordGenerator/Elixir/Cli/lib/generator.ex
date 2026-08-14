defmodule PasswordGenerator.Generator do
  @moduledoc """
  Secure, configurable password generation shared by CLI and tests.

  Mirrors the Ruby/Java behaviour:

  - length must be >= 1
  - at least one category must be enabled
  - each enabled category contributes at least one char
  - result is shuffled

  Returns `{:ok, password}` or `{:error, message}`.
  """

  @upper "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lower "abcdefghijklmnopqrstuvwxyz"
  @digits "0123456789"
  @symbols "!@#$%^&*()_+-=[]{}|;:,.<>?"

  def generate(length \\ 16, use_upper \\ true, use_lower \\ true, use_digits \\ true, use_symbols \\ true)

  def generate(length, use_upper, use_lower, use_digits, use_symbols) do
    cond do
      not is_integer(length) or length < 1 ->
        {:error, "Password length must be at least 1"}

      true ->
        categories =
          []
          |> maybe_add(@upper, use_upper)
          |> maybe_add(@lower, use_lower)
          |> maybe_add(@digits, use_digits)
          |> maybe_add(@symbols, use_symbols)

        if categories == [] do
          {:error, "At least one character category must be enabled"}
        else
          if length < length(categories) do
            {:error,
             "Password length must be at least #{length(categories)} when #{length(categories)} categories are enabled"}
          else
            {:ok, build(length, categories)}
          end
        end
    end
  end

  defp maybe_add(categories, _chars, false), do: categories
  defp maybe_add(categories, chars, true), do: [chars | categories]

  defp build(length, categories) do
    chars =
      Enum.map(categories, fn category ->
        category |> String.graphemes() |> Enum.random()
      end)

    all = categories |> Enum.join() |> String.graphemes()
    rest = Stream.repeatedly(fn -> Enum.random(all) end) |> Enum.take(length - length(chars))
    (chars ++ rest) |> Enum.shuffle() |> Enum.join()
  end
end