require 'minitest/autorun'
require_relative '../inboxes'

class TestInboxes < Minitest::Test
  def setup
    $messages.clear
    $next_id = 1
  end

  def test_send_message
    msg = send_message('Alice', 'Hello', 'World')
    assert_equal 1, msg[:id]
    assert_equal 'Alice', msg[:from]
    assert_equal 'Hello', msg[:subject]
    assert_equal 'World', msg[:body]
    assert_equal false, msg[:read]
    refute_nil msg[:created_at]
  end

  def test_increment_id
    send_message('A', 'S1', 'B1')
    msg2 = send_message('B', 'S2', 'B2')
    assert_equal 2, msg2[:id]
  end

  def test_list_messages
    send_message('A', 'S', 'B')
    assert_equal 1, list_messages.length
  end

  def test_read_message_marks_read
    msg = send_message('A', 'S', 'B')
    read = read_message(msg[:id])
    assert_equal msg[:id], read[:id]
    assert_equal true, read[:read]
  end

  def test_read_message_not_found
    assert_nil read_message(999)
  end

  def test_delete_message
    msg = send_message('A', 'S', 'B')
    assert_equal true, delete_message(msg[:id])
    assert_equal 0, list_messages.length
  end

  def test_delete_message_not_found
    assert_equal false, delete_message(999)
  end
end