defmodule CalculatorTest do
  use ExUnit.Case, async: true

  test "add returns correct sum" do
    assert Calculator.calculate(2, 3, "add") == {:ok, 5}
    assert Calculator.calculate(-1, 1, "add") == {:ok, 0}
    assert Calculator.calculate(0, 0, "add") == {:ok, 0}
  end

  test "subtract returns correct difference" do
    assert Calculator.calculate(5, 3, "subtract") == {:ok, 2}
    assert Calculator.calculate(0, 5, "subtract") == {:ok, -5}
    assert Calculator.calculate(-1, -1, "subtract") == {:ok, 0}
  end

  test "multiply returns correct product" do
    assert Calculator.calculate(2, 3, "multiply") == {:ok, 6}
    assert Calculator.calculate(0, 5, "multiply") == {:ok, 0}
    assert Calculator.calculate(-2, 3, "multiply") == {:ok, -6}
  end

  test "divide returns correct quotient" do
    assert Calculator.calculate(6, 3, "divide") == {:ok, 2}
    assert Calculator.calculate(5, 2, "divide") == {:ok, 2.5}
    assert Calculator.calculate(0, 5, "divide") == {:ok, 0}
  end

  test "divide by zero returns error" do
    assert Calculator.calculate(5, 0, "divide") == {:error, "Cannot divide by zero"}
  end

  test "invalid operator returns error" do
    assert Calculator.calculate(5, 3, "modulo") == {:error, "Invalid operator"}
  end
end
