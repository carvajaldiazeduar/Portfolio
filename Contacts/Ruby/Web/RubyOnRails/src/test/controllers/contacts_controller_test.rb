require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "create valid contact" do
    assert_difference("Contact.count", 1) do
      post contacts_path, params: { contact: { name: "Alice", phone: "123-456-7890", email: "alice@test.com" } }
    end
    assert_redirected_to root_path
  end

  test "create missing name returns 400 json errors" do
    post contacts_path, params: { contact: { name: "", phone: "123-456-7890", email: "alice@test.com" } }, as: :json
    assert_response 400
    body = JSON.parse(response.body)
    assert_equal({ "name" => "Name is required" }, body["errors"])
  end

  test "create invalid email returns 400 json errors" do
    post contacts_path, params: { contact: { name: "Alice", phone: "123-456-7890", email: "bad-email" } }, as: :json
    assert_response 400
    body = JSON.parse(response.body)
    assert_equal({ "email" => "Invalid email format" }, body["errors"])
  end

  test "create invalid phone returns 400 json errors" do
    post contacts_path, params: { contact: { name: "Alice", phone: "123", email: "alice@test.com" } }, as: :json
    assert_response 400
    body = JSON.parse(response.body)
    assert_equal({ "phone" => "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)" }, body["errors"])
  end

  test "create multiple invalid fields returns all errors" do
    post contacts_path, params: { contact: { name: "", phone: "12", email: "bad" } }, as: :json
    assert_response 400
    body = JSON.parse(response.body)
    assert_equal "Name is required", body["errors"]["name"]
    assert_equal "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)", body["errors"]["phone"]
    assert_equal "Invalid email format", body["errors"]["email"]
  end

  test "create html invalid re-renders index with field errors" do
    post contacts_path, params: { contact: { name: "", phone: "12", email: "bad" } }
    assert_response 400
    assert_match(/Name is required/, response.body)
    assert_match(/Phone must be 7-20/, response.body)
    assert_match(/Invalid email format/, response.body)
    assert_match(/field-error/, response.body)
  end

  test "create html valid fields get green border" do
    post contacts_path, params: { contact: { name: "Alice", phone: "123-456-7890", email: "bad" } }
    assert_response 400
    assert_match(/Invalid email format/, response.body)
    assert_match(/field-valid/, response.body)
  end
end
