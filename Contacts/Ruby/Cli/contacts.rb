def add_contact(contacts, name, phone, email)
  contacts << { name: name, phone: phone, email: email }
  puts 'Contact added!'
end

def list_contacts(contacts)
  if contacts.empty?
    puts 'No contacts found.'
    return
  end
  contacts.each_with_index do |c, i|
    puts "#{i}. #{c[:name]} | #{c[:phone]} | #{c[:email]}"
  end
end

def search_contacts(contacts, query)
  results = contacts.select { |c| c[:name].downcase.include?(query.downcase) }
  if results.empty?
    puts 'No contacts found.'
  else
    results.each_with_index do |c, i|
      puts "#{i}. #{c[:name]} | #{c[:phone]} | #{c[:email]}"
    end
  end
  results
end

def delete_contact(contacts, index)
  if index >= 0 && index < contacts.length
    removed = contacts.delete_at(index)
    puts "Deleted #{removed[:name]}"
  else
    puts 'Invalid index.'
  end
end

def main
  contacts = []
  loop do
    puts "\n--- Contact Manager ---"
    puts '1. Add Contact'
    puts '2. List Contacts'
    puts '3. Search Contacts'
    puts '4. Delete Contact'
    puts '5. Exit'
    print 'Choose an option: '
    choice = gets.to_s.strip
    case choice
    when '1'
      print 'Name: '
      name = gets.to_s.strip
      print 'Phone: '
      phone = gets.to_s.strip
      print 'Email: '
      email = gets.to_s.strip
      add_contact(contacts, name, phone, email)
    when '2'
      list_contacts(contacts)
    when '3'
      print 'Search query: '
      query = gets.to_s.strip
      search_contacts(contacts, query)
    when '4'
      list_contacts(contacts)
      print 'Enter index to delete: '
      index = gets.to_i
      delete_contact(contacts, index)
    when '5'
      puts 'Goodbye!'
      break
    end
  end
end

main if __FILE__ == $PROGRAM_NAME