def add_contact(contacts, name, phone, email)
  name = name.to_s.strip
  phone = phone.to_s.strip
  email = email.to_s.strip
  errors = validate_contact(name, phone, email)
  if errors.empty?
    contacts << { name: name, phone: phone, email: email }
    puts 'Contact added!'
    true
  else
    errors.each_value { |msg| warn msg }
    false
  end
end

def validate_contact(name, phone, email)
  errors = {}
  if name.empty?
    errors[:name] = 'Name is required'
  elsif name.length < 2 || name.length > 100 || !name.match?(/\A[A-Za-zÀ-ÿ' .-]+\z/)
    errors[:name] = 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)'
  end
  if phone.empty?
    errors[:phone] = 'Phone is required'
  elsif !phone.match?(/\A[0-9 +().-]{7,20}\z/)
    errors[:phone] = 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)'
  end
  if email.empty?
    errors[:email] = 'Email is required'
  elsif !email.match?(/\A[^\s@]+@[^\s@]+\.[^\s@]{2,}\z/)
    errors[:email] = 'Invalid email format'
  end
  errors
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