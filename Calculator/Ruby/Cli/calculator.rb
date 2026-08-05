def add(a, b)
  a + b
end

def subtract(a, b)
  a - b
end

def multiply(a, b)
  a * b
end

def divide(a, b)
  raise ArgumentError, 'Cannot divide by zero' if b.zero?
  a / b
end

def show_menu
  puts "\n=== Simple Calculator ==="
  puts '1. Add'
  puts '2. Subtract'
  puts '3. Multiply'
  puts '4. Divide'
  puts '5. Exit'
end

def get_number(prompt)
  loop do
    print prompt
    input = gets.to_s.strip
    begin
      return Float(input)
    rescue ArgumentError
      puts 'Invalid input. Please enter a number.'
    end
  end
end

def main
  operations = {
    '1' => %i[add +],
    '2' => %i[subtract -],
    '3' => %i[multiply *],
    '4' => %i[divide /]
  }

  loop do
    show_menu
    print 'Choose an option (1-5): '
    choice = gets.to_s.strip

    break if choice == '5'

    unless operations.key?(choice)
      puts 'Invalid option. Please try again.'
      next
    end

    num1 = get_number('Enter first number: ')
    num2 = get_number('Enter second number: ')

    func, op = operations[choice]
    begin
      result = send(func, num1, num2)
      puts "\n#{num1} #{op} #{num2} = #{result}"
    rescue ArgumentError => e
      puts "\n#{e.message}"
    end
  end
end

main if __FILE__ == $PROGRAM_NAME