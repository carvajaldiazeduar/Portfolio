require 'minitest/autorun'
require_relative '../calculator'

class TestCalculator < Minitest::Test
  def test_add
    assert_in_delta 5.0, add(2.0, 3.0)
  end

  def test_subtract
    assert_in_delta 2.0, subtract(5.0, 3.0)
  end

  def test_multiply
    assert_in_delta 12.0, multiply(3.0, 4.0)
  end

  def test_divide
    assert_in_delta 2.5, divide(5.0, 2.0)
  end

  def test_divide_by_zero
    assert_raises(ArgumentError) { divide(5.0, 0.0) }
  end

  def test_negative_numbers
    assert_in_delta(-1.0, add(-2.0, 1.0))
    assert_in_delta(-2.0, subtract(-1.0, 1.0))
  end

  def test_float_precision
    assert_in_delta 0.3, add(0.1, 0.2)
  end
end