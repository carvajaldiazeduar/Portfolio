defmodule PasswordGenerator.Generator do
  @upper "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lower "abcdefghijklmnopqrstuvwxyz"
  @digits "0123456789"
  @symbols "!@#$%^&*()-_=+[]{}"

  def generate(length, uppercase, lowercase, numbers, symbols)
      when is_integer(length) and length >= 1 do
    alphabet =
      [uppercase && @upper, lowercase && @lower, numbers && @digits, symbols && @symbols]
      |> Enum.reject(&is_nil/1)
      |> Enum.join()

    if alphabet == "" do
      {:error, "At least one character set must be enabled"}
    else
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
