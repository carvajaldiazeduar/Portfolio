require 'minitest/autorun'
require_relative '../tasks'

class TestTasks < Minitest::Test
  def test_add_task
    tasks = []
    id = add_task(tasks, 'Buy milk', 'Go to the store')
    assert_equal 1, id
    assert_equal 1, tasks.length
    assert_equal 'Buy milk', tasks[0][:title]
    assert_equal 'Go to the store', tasks[0][:description]
    assert_equal false, tasks[0][:completed]
  end

  def test_next_id
    tasks = []
    add_task(tasks, 'A', '')
    add_task(tasks, 'B', '')
    assert_equal 3, next_id(tasks)
  end

  def test_list_tasks_empty
    assert_output(/No tasks/) { list_tasks([]) }
  end

  def test_list_tasks_with_data
    tasks = [{ id: 1, title: 'A', created_at: 'now', completed: false }]
    assert_output(/A/) { list_tasks(tasks) }
  end

  def test_complete_task
    tasks = []
    id = add_task(tasks, 'A', '')
    assert_equal true, complete_task(tasks, id)
    assert_equal true, tasks[0][:completed]
  end

  def test_complete_task_not_found
    tasks = []
    assert_equal false, complete_task(tasks, 999)
  end

  def test_delete_task
    tasks = []
    id = add_task(tasks, 'A', '')
    assert_equal true, delete_task(tasks, id)
    assert_equal 0, tasks.length
  end

  def test_delete_task_not_found
    tasks = []
    assert_equal false, delete_task(tasks, 999)
  end
end