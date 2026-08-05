UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.freeze
LOWERCASE = 'abcdefghijklmnopqrstuvwxyz'.freeze
DIGITS = '0123456789'.freeze
SYMBOLS = '!@#$%^&*()_+-=[]{}|;:,.<>?'.freeze

ALL_CHARS = {
  'upper' => UPPERCASE,
  'lower' => LOWERCASE,
  'digits' => DIGITS,
  'symbols' => SYMBOLS
}.freeze

def generate_password(length = 16, use_upper: true, use_lower: true, use_digits: true, use_symbols: true)
  raise ArgumentError, 'Password length must be at least 1' if length < 1

  categories = []
  categories << UPPERCASE if use_upper
  categories << LOWERCASE if use_lower
  categories << DIGITS if use_digits
  categories << SYMBOLS if use_symbols

  raise ArgumentError, 'At least one character category must be enabled' if categories.empty?
  raise ArgumentError, "Password length must be at least #{categories.length} when #{categories.length} categories are enabled" if length < categories.length

  password = categories.map { |cat| cat[rand(cat.length)] }
  all_chars = categories.join
  (length - categories.length).times { password << all_chars[rand(all_chars.length)] }
  password.shuffle.join
end

def show_menu
  puts '=== Password Generator ==='
  print 'Length (default 16): '
  length = gets.to_s.strip
  length = length.empty? ? 16 : (Integer(length, exception: false) || 16)

  print 'Include uppercase? (Y/n): '
  use_upper = gets.to_s.strip.downcase != 'n'
  print 'Include lowercase? (Y/n): '
  use_lower = gets.to_s.strip.downcase != 'n'
  print 'Include digits? (Y/n): '
  use_digits = gets.to_s.strip.downcase != 'n'
  print 'Include symbols? (Y/n): '
  use_symbols = gets.to_s.strip.downcase != 'n'

  begin
    password = generate_password(length, use_upper: use_upper, use_lower: use_lower, use_digits: use_digits, use_symbols: use_symbols)
    puts "\nGenerated password: #{password}"
  rescue ArgumentError => e
    puts "Error: #{e.message}"
  end
end

def parse_args(args)
  opts = { length: 16, use_upper: true, use_lower: true, use_digits: true, use_symbols: true }
  i = 0
  while i < args.length
    case args[i]
    when '-l', '--length'
      opts[:length] = Integer(args[i + 1], exception: false) || 16
      i += 1
    when '--no-upper'
      opts[:use_upper] = false
    when '--no-lower'
      opts[:use_lower] = false
    when '--no-digits'
      opts[:use_digits] = false
    when '--no-symbols'
      opts[:use_symbols] = false
    end
    i += 1
  end
  opts
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length > 0
    opts = parse_args(ARGV)
    begin
      puts generate_password(opts[:length], use_upper: opts[:use_upper], use_lower: opts[:use_lower], use_digits: opts[:use_digits], use_symbols: opts[:use_symbols])
    rescue ArgumentError => e
      warn "Error: #{e.message}"
      exit 1
    end
  else
    show_menu
  end
end