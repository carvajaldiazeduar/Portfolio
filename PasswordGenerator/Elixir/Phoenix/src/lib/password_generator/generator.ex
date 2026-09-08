defmodule PasswordGenerator.Generator do
  @upper "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lower "abcdefghijklmnopqrstuvwxyz"
  @digits "0123456789"
  @symbols "!@#$%^&*()-_=+[]{}"

  def generate(length, uppercase, lowercase, numbers, symbols)
      when is_integer(length) and length >= 1 do
    flags = [uppercase, lowercase, numbers, symbols]
    categories = Enum.count(flags, & &1)

    alphabet =
      Enum.zip([uppercase, lowercase, numbers, symbols], [@upper, @lower, @digits, @symbols])
      |> Enum.filter(fn {enabled, _chars} -> enabled end)
      |> Enum.map_join(fn {_enabled, chars} -> chars end)

    cond do
      alphabet == "" ->
        {:error, "At least one character category must be enabled"}

      length < categories ->
        {:error,
         "Password length must be at least #{categories} when #{categories} categories are enabled"}

      true ->
        {:ok,
         for(
           _ <- 1..length,
           into: "",
           do: <<:rand.uniform(byte_size(alphabet)) |> then(&:binary.at(alphabet, &1 - 1))>>
         )}
    end
  end

  def generate(_length, _uppercase, _lowercase, _numbers, _symbols),
    do: {:error, "Password length must be at least 1"}
end