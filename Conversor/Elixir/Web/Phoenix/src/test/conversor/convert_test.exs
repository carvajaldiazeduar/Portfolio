defmodule Conversor.ConversorTest do
  use ExUnit.Case, async: true

  test "categories lists supported types" do
    assert "length" in Conversor.categories()
    assert "weight" in Conversor.categories()
    assert "temperature" in Conversor.categories()
  end

  test "unit conversion for length" do
    assert {:ok, result} = Conversor.convert(1, "km", "m")
    assert_in_delta result, 1000.0, 0.0001
  end

  test "unit conversion for weight" do
    assert {:ok, result} = Conversor.convert(1, "kg", "g")
    assert_in_delta result, 1000.0, 0.0001
  end

  test "temperature celsius to fahrenheit" do
    assert {:ok, result} = Conversor.convert(0, "C", "F")
    assert_in_delta result, 32.0, 0.0001
  end

  test "temperature celsius to kelvin" do
    assert {:ok, result} = Conversor.convert(0, "C", "K")
    assert_in_delta result, 273.15, 0.0001
  end

  test "same unit returns same value" do
    assert {:ok, result} = Conversor.convert(5, "m", "m")
    assert_in_delta result, 5.0, 0.0001
  end

  test "incompatible units return error" do
    assert {:error, message} = Conversor.convert(5, "m", "kg")
    assert message == "Incompatible units"
  end
end