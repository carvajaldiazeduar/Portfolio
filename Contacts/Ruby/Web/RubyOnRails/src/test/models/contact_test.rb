require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid contact" do
    contact = Contact.new(name: "Alice", phone: "123-456-7890", email: "alice@test.com")
    assert contact.valid?
  end

  test "name is required" do
    contact = Contact.new(name: "   ", phone: "123-456-7890", email: "alice@test.com")
    assert_not contact.valid?
    assert_equal "Name is required", contact.errors[:name].uniq.first
  end

  test "name too short" do
    contact = Contact.new(name: "A", phone: "123-456-7890", email: "alice@test.com")
    assert_not contact.valid?
    assert_equal "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)", contact.errors[:name].uniq.first
  end

  test "name too long" do
    contact = Contact.new(name: "A" * 101, phone: "123-456-7890", email: "alice@test.com")
    assert_not contact.valid?
    assert_equal "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)", contact.errors[:name].uniq.first
  end

  test "name invalid characters" do
    contact = Contact.new(name: "A@B", phone: "123-456-7890", email: "alice@test.com")
    assert_not contact.valid?
    assert_equal "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)", contact.errors[:name].uniq.first
  end

  test "name strips surrounding whitespace" do
    contact = Contact.new(name: "  Alice  ", phone: "123-456-7890", email: "alice@test.com")
    assert contact.valid?
    assert_equal "Alice", contact.name
  end

  test "phone is required" do
    contact = Contact.new(name: "Alice", phone: "", email: "alice@test.com")
    assert_not contact.valid?
    assert_equal "Phone is required", contact.errors[:phone].uniq.first
  end

  test "phone too short" do
    contact = Contact.new(name: "Alice", phone: "123", email: "alice@test.com")
    assert_not contact.valid?
    assert_equal "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)", contact.errors[:phone].uniq.first
  end

  test "phone invalid characters" do
    contact = Contact.new(name: "Alice", phone: "abcdefg", email: "alice@test.com")
    assert_not contact.valid?
    assert_equal "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)", contact.errors[:phone].uniq.first
  end

  test "phone strips surrounding whitespace" do
    contact = Contact.new(name: "Alice", phone: " 123-456-7890 ", email: "alice@test.com")
    assert contact.valid?
    assert_equal "123-456-7890", contact.phone
  end

  test "email is required" do
    contact = Contact.new(name: "Alice", phone: "123-456-7890", email: "")
    assert_not contact.valid?
    assert_equal "Email is required", contact.errors[:email].uniq.first
  end

  test "email invalid format" do
    contact = Contact.new(name: "Alice", phone: "123-456-7890", email: "not-an-email")
    assert_not contact.valid?
    assert_equal "Invalid email format", contact.errors[:email].uniq.first
  end

  test "email strips surrounding whitespace" do
    contact = Contact.new(name: "Alice", phone: "123-456-7890", email: " alice@test.com ")
    assert contact.valid?
    assert_equal "alice@test.com", contact.email
  end
end
