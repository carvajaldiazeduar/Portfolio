require 'time'

$messages = []
$next_id = 1

def send_message(from_, subject, body)
  msg = {
    id: $next_id,
    from: from_,
    subject: subject,
    body: body,
    read: false,
    created_at: Time.now.iso8601
  }
  $messages << msg
  $next_id += 1
  msg
end

def list_messages
  $messages
end

def read_message(id)
  msg = $messages.find { |m| m[:id] == id }
  msg[:read] = true if msg
  msg
end

def delete_message(id)
  index = $messages.index { |m| m[:id] == id }
  $messages.delete_at(index) if index
  !index.nil?
end

def main
  loop do
    puts "\n=== Inbox CLI ==="
    puts '1. Send message'
    puts '2. List messages'
    puts '3. Read message'
    puts '4. Delete message'
    puts '5. Exit'
    print 'Choice: '
    choice = gets.to_s.strip

    case choice
    when '1'
      print 'From: '
      from_ = gets.to_s.strip
      print 'Subject: '
      subject = gets.to_s.strip
      print 'Body: '
      body = gets.to_s.strip
      msg = send_message(from_, subject, body)
      puts "Message sent (id=#{msg[:id]})"
    when '2'
      msgs = list_messages
      if msgs.empty?
        puts 'No messages.'
      else
        msgs.each do |m|
          status = m[:read] ? 'R' : 'U'
          puts "[#{m[:id]}] #{status} From: #{m[:from]} | Subject: #{m[:subject]} | #{m[:created_at]}"
        end
      end
    when '3'
      print 'Message ID: '
      id = Integer(gets.to_s.strip, exception: false)
      unless id
        puts 'Invalid ID.'
        next
      end
      msg = read_message(id)
      if msg
        puts "From: #{msg[:from]}"
        puts "Subject: #{msg[:subject]}"
        puts "Date: #{msg[:created_at]}"
        puts "---\n#{msg[:body]}"
      else
        puts 'Message not found.'
      end
    when '4'
      print 'Message ID: '
      id = Integer(gets.to_s.strip, exception: false)
      unless id
        puts 'Invalid ID.'
        next
      end
      if delete_message(id)
        puts 'Message deleted.'
      else
        puts 'Message not found.'
      end
    when '5'
      break
    end
  end
end

main if __FILE__ == $PROGRAM_NAME