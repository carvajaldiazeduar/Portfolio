defmodule Conversor do
  @moduledoc """
  Unit conversion logic (length, weight, temperature) shared by CLI and Web.
  """

  @conversion %{
    "length" => %{
      "m" => 1.0,
      "km" => 0.001,
      "mi" => 0.000621371,
      "ft" => 3.28084,
      "in" => 39.3701,
      "cm" => 100.0
    },
    "weight" => %{
      "kg" => 1.0,
      "g" => 1000.0,
      "lb" => 2.20462,
      "oz" => 35.274,
      "mg" => 1_000_000.0
    },
    "temperature" => %{
      "C" => :celsius,
      "F" => :fahrenheit,
      "K" => :kelvin
    }
  }

  @category_units %{
    "length" => ~w(m km mi ft in cm),
    "weight" => ~w(kg g lb oz mg),
    "temperature" => ~w(C F K)
  }

  def categories, do: Map.keys(@conversion)

  def units_for(category), do: Map.get(@category_units, category, [])

  def category_units, do: @category_units

  def convert(value, from, to) do
    for {category, units} <- @conversion,
        Map.has_key?(units, from) and Map.has_key?(units, to) do
      if category == "temperature" do
        convert_temperature(value, from, to)
      else
        value / units[from] * units[to]
      end
    end
    |> case do
      [result] -> {:ok, result}
      [] -> {:error, "Incompatible units"}
    end
  end

  defp convert_temperature(value, from, to) when from == to, do: value

  defp convert_temperature(value, "C", "F"), do: value * 9.0 / 5.0 + 32
  defp convert_temperature(value, "C", "K"), do: value + 273.15

  defp convert_temperature(value, "F", "C"), do: (value - 32) * 5.0 / 9.0

  defp convert_temperature(value, "F", "K"), do: (value - 32) * 5.0 / 9.0 + 273.15

  defp convert_temperature(value, "K", "C"), do: value - 273.15

  defp convert_temperature(value, "K", "F"), do: (value - 273.15) * 9.0 / 5.0 + 32
end