defmodule Calculator do
  @moduledoc """
  Calculator core operations. Reused by both CLI and Web.
  """

  @allowed_operators ~w(add subtract multiply divide)

  def allowed_operators, do: @allowed_operators

  def calculate(a, b, operator) when operator in @allowed_operators do
    case operator do
      "add" -> {:ok, a + b}
      "subtract" -> {:ok, a - b}
      "multiply" -> {:ok, a * b}
      "divide" when b == 0 -> {:error, "Cannot divide by zero"}
      "divide" -> {:ok, a / b}
    end
  end

  def calculate(_a, _b, _operator), do: {:error, "Invalid operator"}
end