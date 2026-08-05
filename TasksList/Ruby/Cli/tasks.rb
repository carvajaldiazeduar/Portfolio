require 'time'

def next_id(tasks)
  tasks.empty? ? 1 : tasks.map { |t| t[:id] }.max + 1
end

def add_task(tasks, title, description)
  task = {
    id: next_id(tasks),
    title: title,
    description: description,
    completed: false,
    created_at: Time.now.iso8601
  }
  tasks << task
  task[:id]
end

def list_tasks(tasks)
  if tasks.empty?
    puts 'No tasks found.'
    return
  end
  tasks.each do |t|
    status = t[:completed] ? '[x]' : '[ ]'
    puts "#{status} #{t[:id]}. #{t[:title]} - #{t[:created_at]}"
  end
end

def complete_task(tasks, id)
  task = tasks.find { |t| t[:id] == id }
  task[:completed] = true if task
  !task.nil?
end

def delete_task(tasks, id)
  index = tasks.index { |t| t[:id] == id }
  tasks.delete_at(index) if index
  !index.nil?
end

def main
  tasks = []
  loop do
    puts "\n=== Tasks List ==="
    puts '1. Add Task'
    puts '2. List Tasks'
    puts '3. Complete Task'
    puts '4. Delete Task'
    puts '5. Exit'
    print 'Choose an option: '
    choice = gets.to_s.strip

    case choice
    when '1'
      print 'Title: '
      title = gets.to_s.strip
      print 'Description: '
      description = gets.to_s.strip
      add_task(tasks, title, description)
      puts 'Task added.'
    when '2'
      list_tasks(tasks)
    when '3'
      print 'Task ID to complete: '
      tid = Integer(gets.to_s.strip, exception: false)
      unless tid
        puts 'Invalid ID.'
        next
      end
      if complete_task(tasks, tid)
        puts 'Task completed.'
      else
        puts 'Task not found.'
      end
    when '4'
      print 'Task ID to delete: '
      tid = Integer(gets.to_s.strip, exception: false)
      unless tid
        puts 'Invalid ID.'
        next
      end
      if delete_task(tasks, tid)
        puts 'Task deleted.'
      else
        puts 'Task not found.'
      end
    when '5'
      puts 'Goodbye!'
      break
    else
      puts 'Invalid option.'
    end
  end
end

main if __FILE__ == $PROGRAM_NAME