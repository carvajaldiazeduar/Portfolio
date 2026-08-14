defmodule Conversor.CLI do
  @moduledoc """
  Interactive CLI for Conversor built as a mix escript.
  """

  def main(_args) do
    IO.puts("=== Unit Converter ===")

    loop()
  end

  defp loop do
    IO.puts("")
    IO.puts("Categories:")

    Conversor.categories()
    |> Enum.with_index(1)
    |> Enum.each(fn {category, index} -> IO.puts("  #{index}. #{category}") end)

    IO.puts("  0. Exit")

    choice = IO.gets("Choose a category: ") |> String.trim()

    case Integer.parse(choice) do
      {0, ""} ->
        IO.puts("Goodbye!")
        System.halt(0)

      {index, ""} ->
        categories = Conversor.categories()

        if index >= 1 and index <= length(categories) do
          category = Enum.at(categories, index - 1)
          convert_in_category(category)
        else
          IO.puts("Invalid option. Please try again.")
        end

      _ ->
        IO.puts("Invalid option. Please try again.")
    end

    loop()
  end

  defp convert_in_category(category) do
    units = Conversor.units_for(category)
    IO.puts("Units: #{Enum.join(units, ", ")}")
    from = IO.gets("From unit: ") |> String.trim()
    to = IO.gets("To unit: ") |> String.trim()
    value = get_value()

    case Conversor.convert(value, from, to) do
      {:ok, result} -> IO.puts("#{value} #{from} = #{result} #{to}")
      {:error, message} -> IO.puts("Error: #{message}")
    end
  end

  defp get_value do
    case IO.gets("Value: ") |> String.trim() |> Float.parse() do
      {number, ""} ->
        number

      _ ->
        IO.puts("Invalid number.")
        get_value()
    end
  end
end
