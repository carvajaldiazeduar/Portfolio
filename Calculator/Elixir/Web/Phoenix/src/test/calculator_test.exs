defmodule CalculatorTest do
  use ExUnit.Case, async: true

  test "add" do
    assert Calculator.calculate(2, 3, "add") == {:ok, 5}
  end

  test "subtract" do
    assert Calculator.calculate(10, 4, "subtract") == {:ok, 6}
  end

  test "multiply" do
    assert Calculator.calculate(6, 7, "multiply") == {:ok, 42}
  end

  test "divide" do
    assert Calculator.calculate(10, 4, "divide") == {:ok, 2.5}
  end

  test "division by zero returns error" do
    assert Calculator.calculate(10, 0, "divide") == {:error, "Cannot divide by zero"}
  end

  test "invalid operator returns error" do
    assert Calculator.calculate(10, 4, "modulo") == {:error, "Invalid operator"}
  end
end
