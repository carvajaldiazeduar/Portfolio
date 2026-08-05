require 'minitest/autorun'
require_relative '../contacts'

class TestContacts < Minitest::Test
  def test_add_contact
    contacts = []
    add_contact(contacts, 'Alice', '123-456', 'alice@test.com')
    assert_equal 1, contacts.length
    assert_equal 'Alice', contacts[0][:name]
    assert_equal '123-456', contacts[0][:phone]
    assert_equal 'alice@test.com', contacts[0][:email]
  end

  def test_list_contacts_empty
    assert_output(/No contacts/) { list_contacts([]) }
  end

  def test_list_contacts_with_data
    contacts = [{ name: 'Alice', phone: '123', email: 'a@b.com' }]
    assert_output(/Alice/) { list_contacts(contacts) }
  end

  def test_search_contacts_found
    contacts = [
      { name: 'Alice', phone: '123', email: 'a@b.com' },
      { name: 'Bob', phone: '456', email: 'b@c.com' },
      { name: 'Alexander', phone: '789', email: 'alex@d.com' }
    ]
    results = search_contacts(contacts, 'al')
    assert_equal 2, results.length
  end

  def test_search_contacts_not_found
    contacts = [{ name: 'Alice', phone: '123', email: 'a@b.com' }]
    results = search_contacts(contacts, 'zzz')
    assert_equal 0, results.length
    assert_output(/No contacts/) { search_contacts(contacts, 'zzz') }
  end

  def test_delete_contact_valid
    contacts = [
      { name: 'Alice', phone: '123', email: 'a@b.com' },
      { name: 'Bob', phone: '456', email: 'b@c.com' }
    ]
    delete_contact(contacts, 0)
    assert_equal 1, contacts.length
    assert_equal 'Bob', contacts[0][:name]
  end

  def test_delete_contact_invalid
    contacts = [{ name: 'Alice', phone: '123', email: 'a@b.com' }]
    assert_output(/Invalid/) { delete_contact(contacts, 5) }
    assert_equal 1, contacts.length
  end
end