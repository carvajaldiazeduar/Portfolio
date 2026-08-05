require 'minitest/autorun'
require_relative '../conversor'

class TestConversor < Minitest::Test
  def test_list_categories
    assert_equal %w[length weight temperature], list_categories
  end

  def test_length_conversion
    assert_in_delta 1000.0, convert(1.0, 'km', 'm')
  end

  def test_weight_conversion
    assert_in_delta 1000.0, convert(1.0, 'kg', 'g')
  end

  def test_same_unit
    assert_in_delta 5.0, convert(5.0, 'm', 'm')
  end

  def test_temperature_c_to_f
    assert_in_delta 212.0, convert(100.0, 'C', 'F')
  end

  def test_temperature_c_to_k
    assert_in_delta 373.15, convert(100.0, 'C', 'K')
  end

  def test_temperature_f_to_c
    assert_in_delta 100.0, convert(212.0, 'F', 'C')
  end

  def test_temperature_k_to_c
    assert_in_delta 100.0, convert(373.15, 'K', 'C')
  end

  def test_incompatible_units
    assert_raises(ArgumentError) { convert(1.0, 'm', 'kg') }
  end
end