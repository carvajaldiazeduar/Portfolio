require 'minitest/autorun'
require_relative '../password_generator'

class TestPasswordGenerator < Minitest::Test
  def test_default_length
    assert_equal 16, generate_password.length
  end

  def test_custom_length
    assert_equal 24, generate_password(24).length
  end

  def test_contains_guaranteed_characters
    password = generate_password(10, use_upper: true, use_lower: true, use_digits: true, use_symbols: true)
    assert_match(/[A-Z]/, password)
    assert_match(/[a-z]/, password)
    assert_match(/[0-9]/, password)
    assert_match(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/, password)
  end

  def test_shuffled
    refute_equal('AAAA'.chars, generate_password(4, use_upper: true, use_lower: false, use_digits: false, use_symbols: false).chars.sort)
  end

  def test_length_too_short_raises
    assert_raises(ArgumentError) { generate_password(0) }
  end

  def test_empty_categories_raises
    assert_raises(ArgumentError) { generate_password(16, use_upper: false, use_lower: false, use_digits: false, use_symbols: false) }
  end

  def test_length_less_than_categories_raises
    assert_raises(ArgumentError) { generate_password(1, use_upper: true, use_lower: true, use_digits: true, use_symbols: true) }
  end
end