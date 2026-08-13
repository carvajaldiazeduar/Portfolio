defmodule Calculator.CLI do
  @moduledoc """
  Interactive CLI for Calculator built as a mix escript.
  """

  def main(_args) do
    loop()
  end

  defp loop do
    IO.puts("""
    === Simple Calculator ===
    1. Add
    2. Subtract
    3. Multiply
    4. Divide
    5. Exit
    """)

    case IO.gets("Choose an option (1-5): ") |> String.trim() do
      "5" ->
        IO.puts("Goodbye!")
        System.halt(0)

      "" ->
        loop()

      choice ->
        dispatch(choice)
        loop()
    end
  end

  defp dispatch(choice) do
    case operator_for(choice) do
      nil ->
        IO.puts("Invalid option. Please try again.")

      operator ->
        a = get_number("Enter first number: ")
        b = get_number("Enter second number: ")

        case Calculator.calculate(a, b, operator) do
          {:ok, result} -> IO.puts("#{a} #{symbol(operator)} #{b} = #{result}")
          {:error, message} -> IO.puts(message)
        end
    end
  end

  defp operator_for("1"), do: "add"
  defp operator_for("2"), do: "subtract"
  defp operator_for("3"), do: "multiply"
  defp operator_for("4"), do: "divide"
  defp operator_for(_), do: nil

  defp symbol("add"), do: "+"
  defp symbol("subtract"), do: "-"
  defp symbol("multiply"), do: "*"
  defp symbol("divide"), do: "/"

  defp get_number(prefix) do
    case IO.gets(prefix) |> String.trim() |> Float.parse() do
      {number, ""} ->
        number

      _ ->
        IO.puts("Invalid input. Please enter a number.")
        get_number(prefix)
    end
  end
end