class ConversorController < ApplicationController
  CONVERSIONS = {
    "length" => {
      "meter" => 1.0,
      "kilometer" => 1000.0,
      "centimeter" => 0.01,
      "millimeter" => 0.001,
      "mile" => 1609.344,
      "yard" => 0.9144,
      "foot" => 0.3048,
      "inch" => 0.0254
    },
    "weight" => {
      "kilogram" => 1.0,
      "gram" => 0.001,
      "milligram" => 0.000001,
      "pound" => 0.453592,
      "ounce" => 0.0283495
    },
    "temperature" => {
      "celsius" => nil,
      "fahrenheit" => nil,
      "kelvin" => nil
    }
  }

  CATEGORIES = [
    ["Length", %w[meter kilometer centimeter millimeter mile yard foot inch]],
    ["Weight", %w[kilogram gram milligram pound ounce]],
    ["Temperature", %w[celsius fahrenheit kelvin]]
  ].freeze

  def index
    @result = nil
    @error = nil
  end

  def convert
    value = params[:value].to_f
    from_unit = params[:from_unit].to_s.downcase
    to_unit = params[:to_unit].to_s.downcase

    temperature = CONVERSIONS["temperature"]
    if temperature.key?(from_unit) && temperature.key?(to_unit)
      @result = convert_temperature(value, from_unit, to_unit)
      @unit = to_unit
      render :index
      return
    end

    CONVERSIONS.each do |_category, factors|
      next unless factors
      if factors.key?(from_unit) && factors.key?(to_unit)
        @result = value * factors[from_unit] / factors[to_unit]
        @unit = to_unit
        render :index
        return
      end
    end

    @error = "Unsupported conversion"
    render :index
  end

  private

  def convert_temperature(value, from_unit, to_unit)
    return value if from_unit == to_unit

    if from_unit == "celsius"
      return value * 9.0 / 5.0 + 32 if to_unit == "fahrenheit"
      return value + 273.15 if to_unit == "kelvin"
    end

    if from_unit == "fahrenheit"
      return (value - 32) * 5.0 / 9.0 if to_unit == "celsius"
      return (value - 32) * 5.0 / 9.0 + 273.15 if to_unit == "kelvin"
    end

    if from_unit == "kelvin"
      return value - 273.15 if to_unit == "celsius"
      return (value - 273.15) * 9.0 / 5.0 + 32 if to_unit == "fahrenheit"
    end

    value
  end
end